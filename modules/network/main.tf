# Create VPC
resource "google_compute_network" "vpc" {
  project                 = var.project
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}

# Create subnets public & private as per provided map
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name                     = each.key
  ip_cidr_range            = each.value.cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = lookup(each.value, "private_access", true)
  project                  = var.project

  dynamic "secondary_ip_range" {
    for_each = lookup(each.value, "enable_secondary", true) ? [
      {
        range_name    = "${each.key}-pods"
        ip_cidr_range = each.value.pod_cidr_range
      },
      {
        range_name    = "${each.key}-services"
        ip_cidr_range = each.value.svc_cidr_range
      }
    ] : []

    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}

resource "google_compute_subnetwork" "proxy_subnets" {
  for_each = var.enable_proxy_subnets ? var.proxy_subnets : {}

  name          = "${each.key}-proxy"
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  project       = var.project
  network       = google_compute_network.vpc.id

  purpose = each.value.purpose
  role    = "ACTIVE"

  depends_on = [google_compute_network.vpc]
}


# Enable private service connection (for Cloud SQL private IP) - consumer
resource "google_service_networking_connection" "private_vpc_connection" {
  for_each                = local.create_psa
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_range[each.key].name]
}

resource "google_compute_global_address" "private_range" {
  for_each      = local.create_psa
  name          = each.key
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = each.value.private_services_prefix_length
  network       = google_compute_network.vpc.id
  ip_version    = "IPV4"
  address       = each.value.ip_address
}


# Cloud NAT for private subnets
resource "google_compute_router" "nat_router" {
  name    = "${var.vpc_name}-nat-router"
  network = google_compute_network.vpc.id
  region  = var.region
  project = var.project
}

resource "google_compute_router_nat" "cloud_nat" {
  name                               = "${var.vpc_name}-cloud-nat"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  project                            = var.project
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  dynamic "subnetwork" {
    for_each = {
      for name, cfg in var.subnets :
      name => cfg
      if lookup(cfg, "private_access", true) == true
    }
    content {
      name                    = google_compute_subnetwork.subnets[subnetwork.key].id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
}

locals {
  create_rules = var.firewall_rules.enabled ? {
    for r in var.firewall_rules.rules : r.name => r
  } : {}
  create_psa = var.private_service_ranges.enabled ? {
    for r in var.private_service_ranges.psa : r.name => r
  } : {}
  peering_map = var.peerings.enabled ? {
    for p in var.peerings.connections : p.name => p
  } : {}
}

resource "google_compute_firewall" "rules" {
  for_each = local.create_rules

  name    = each.key
  network = google_compute_network.vpc.self_link

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
