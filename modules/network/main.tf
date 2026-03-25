locals {
  # Backward‑compatible VPC map
  effective_vpcs = length(var.vpcs) > 0 ? var.vpcs : {
    (var.vpc_name) = {
      project      = var.project
      routing_mode = var.routing_mode
      region       = var.region
    }
  }

  # Handle legacy single‑VPC configs (your exact format)
  is_single_vpc_mode = length(var.vpcs) == 0

  # Subnets: legacy flat map → single VPC entry
  effective_subnets = local.is_single_vpc_mode ? {
    (var.vpc_name) = var.subnets
  } : var.subnets

  # Proxy subnets: legacy flat map → single VPC entry  
  effective_proxy_subnets = local.is_single_vpc_mode ? {
    (var.vpc_name) = var.proxy_subnets
  } : var.proxy_subnets

  # Private service ranges: legacy object → single VPC entry
  effective_private_service_ranges = local.is_single_vpc_mode ? {
    (var.vpc_name) = var.private_service_ranges
  } : var.private_service_ranges

  # Firewall rules: legacy object → single VPC entry
  effective_firewall_rules = local.is_single_vpc_mode ? {
    (var.vpc_name) = var.firewall_rules
  } : var.firewall_rules

  # ✅ FIXED: Flatten subnets using flatten() + setunion()
  subnet_flat = flatten([
    for vpc_name, subnet_map in local.effective_subnets : [
      for subnet_name, cfg in subnet_map : {
        key         = "${vpc_name}/${subnet_name}"
        vpc_name    = vpc_name
        subnet_name = subnet_name
        config      = cfg
      }
    ]
  ])
  subnet_map = { for item in local.subnet_flat : item.key => merge(item.config, {
    vpc_name    = item.vpc_name
    subnet_name = item.subnet_name
  }) }

  # ✅ FIXED: Flatten proxy subnets
  proxy_subnet_flat = flatten([
    for vpc_name, subnet_map in local.effective_proxy_subnets : [
      for subnet_name, cfg in subnet_map : {
        key         = "${vpc_name}/${subnet_name}"
        vpc_name    = vpc_name
        subnet_name = subnet_name
        config      = cfg
      }
    ]
  ])
  proxy_subnet_map = var.enable_proxy_subnets ? { for item in local.proxy_subnet_flat : item.key => merge(item.config, {
    vpc_name    = item.vpc_name
    subnet_name = item.subnet_name
  }) } : {}

  # ✅ FIXED: Flatten firewall rules
  firewall_rule_flat = flatten([
    for vpc_name, cfg in local.effective_firewall_rules : cfg.enabled ? [
      for rule in cfg.rules : {
        key      = "${vpc_name}/${rule.name}"
        vpc_name = vpc_name
        rule     = rule
      }
    ] : []
  ])
  firewall_rule_map = { for item in local.firewall_rule_flat : item.key => merge(item.rule, {
    vpc_name = item.vpc_name
  }) }

  # PSA
  create_psa = {
    for vpc_name, cfg in local.effective_private_service_ranges :
    vpc_name => cfg
    if lookup(cfg, "enabled", false)
  }

  peering_map = var.peerings.enabled ? {
    for p in var.peerings.connections : p.name => p
  } : {}
}

# ... all resources unchanged below ...

resource "google_compute_network" "vpc" {
  for_each                = local.effective_vpcs
  project                 = each.value.project
  name                    = each.key
  auto_create_subnetworks = false
  routing_mode            = each.value.routing_mode
}

resource "google_compute_subnetwork" "subnets" {
  for_each = local.subnet_map

  name                     = each.value.subnet_name
  ip_cidr_range            = each.value.cidr
  region                   = lookup(each.value, "region", local.effective_vpcs[each.value.vpc_name].region)
  network                  = google_compute_network.vpc[each.value.vpc_name].id
  private_ip_google_access = lookup(each.value, "private_access", true)
  project                  = local.effective_vpcs[each.value.vpc_name].project

  dynamic "secondary_ip_range" {
    for_each = lookup(each.value, "enable_secondary", true) ? [
      {
        range_name    = "${each.value.subnet_name}-pods"
        ip_cidr_range = lookup(each.value, "pod_cidr_range", null)
      },
      {
        range_name    = "${each.value.subnet_name}-services"
        ip_cidr_range = lookup(each.value, "svc_cidr_range", null)
      }
    ] : []

    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}

resource "google_compute_subnetwork" "proxy_subnets" {
  for_each = local.proxy_subnet_map

  name          = "${each.value.subnet_name}-proxy"
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  project       = local.effective_vpcs[each.value.vpc_name].project
  network       = google_compute_network.vpc[each.value.vpc_name].id

  purpose = each.value.purpose
  role    = "ACTIVE"
}

resource "google_compute_global_address" "private_range" {
  for_each      = local.create_psa
  name          = each.key
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = lookup(each.value.psa[0], "private_services_prefix_length", 24)
  network       = google_compute_network.vpc[each.key].id
  ip_version    = "IPV4"
  address       = lookup(each.value.psa[0], "ip_address", null)
}

resource "google_service_networking_connection" "private_vpc_connection" {
  for_each                = local.create_psa
  network                 = google_compute_network.vpc[each.key].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_range[each.key].name]
}

resource "google_compute_router" "nat_router" {
  for_each = local.effective_vpcs

  name    = "${each.key}-nat-router"
  network = google_compute_network.vpc[each.key].id
  region  = each.value.region
  project = each.value.project
}

resource "google_compute_router_nat" "cloud_nat" {
  for_each = local.effective_vpcs

  name                               = "${each.key}-cloud-nat"
  router                             = google_compute_router.nat_router[each.key].name
  region                             = each.value.region
  project                            = each.value.project
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = {
      for k, cfg in google_compute_subnetwork.subnets :
      k => cfg
      if split("/", k)[0] == each.key
    }

    content {
      name                    = subnetwork.value.id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
}

resource "google_compute_firewall" "rules" {
  for_each = local.firewall_rule_map

  name    = each.value.name
  network = google_compute_network.vpc[each.value.vpc_name].self_link

  direction     = each.value.direction
  priority      = each.value.priority
  source_ranges = each.value.ranges
  target_tags   = each.value.target_tags

  allow {
    protocol = each.value.protocol
    ports    = each.value.ports
  }
}

resource "google_compute_network_peering" "vpc_peering" {
  for_each = local.peering_map

  name                                = each.key
  network                             = each.value.network_self
  peer_network                        = each.value.peer_network
  export_custom_routes                = lookup(each.value, "export_routes", true)
  import_custom_routes                = lookup(each.value, "import_routes", true)
  update_strategy                     = each.value.update_strategy
  stack_type                          = each.value.stack_type
  import_subnet_routes_with_public_ip = each.value.import_subnet_routes_with_public_ip
}
