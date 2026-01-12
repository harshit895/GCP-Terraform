############################################
# MULTI-CLUSTER SUPPORT
############################################

resource "google_container_cluster" "gke" {
  for_each = var.gke_clusters

  name     = each.key
  location = each.value.location_type == "zonal" ? each.value.zones[0] : each.value.region

  remove_default_node_pool = true
  initial_node_count       = 1

  min_master_version = each.value.kubernetes_version

  network             = each.value.network
  subnetwork          = each.value.subnetwork
  deletion_protection = false

  release_channel {
    channel = each.value.release_channel
  }

  private_cluster_config {
    enable_private_nodes    = each.value.enable_private_nodes
    enable_private_endpoint = each.value.enable_private_endpoint
    master_ipv4_cidr_block  = each.value.master_ipv4_cidr_block

    master_global_access_config {
      enabled = true # Access control plane from any region (internal IP)
    }
  }

  dynamic "master_authorized_networks_config" {
    for_each = each.value.enable_master_authorized_networks ? [1] : []

    content {
      private_endpoint_enforcement_enabled = false
      dynamic "cidr_blocks" {
        for_each = lookup(each.value, "authorized_networks", [])

        content {
          cidr_block   = cidr_blocks.value.cidr
          display_name = cidr_blocks.value.name
        }
      }
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = each.value.pods_secondary_range_name
    services_secondary_range_name = each.value.services_secondary_range_name
  }

  maintenance_policy {
    recurring_window {
      start_time = each.value.maintenance_window
      end_time   = timeadd(each.value.maintenance_window, "4h")
      recurrence = "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"
    }
  }

  cluster_autoscaling {
    enabled = false
  }

  security_posture_config {
    mode               = each.value.enable_security_posture ? "BASIC" : "DISABLED"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }

  enable_shielded_nodes = each.value.enable_shielded_nodes

  workload_identity_config {
    workload_pool = "${each.value.project_id}.svc.id.goog"
  }

  addons_config {
    gcs_fuse_csi_driver_config {
      enabled = each.value.enable_gcsfuse
    }

    gcp_filestore_csi_driver_config {
      enabled = each.value.enable_filestore
    }

    gke_backup_agent_config {
      enabled = each.value.enable_backup
    }

    lustre_csi_driver_config {
      enabled = each.value.enable_lustre_csi_driver
    }
  }

  monitoring_config {
    enable_components = each.value.enable_monitoring_components
  }

  enable_legacy_abac = each.value.enable_legacy_abac

  binary_authorization {
    enabled = each.value.enable_binary_authorization
  }

  logging_config {
    enable_components = each.value.enable_logging_components
  }

  cost_management_config {
    enabled = each.value.enable_cost_allocation
  }

  secret_manager_config {
    enabled = each.value.enable_secret_manager
  }
}

############################################
# MULTI-NODE-POOL SUPPORT (per-cluster)
############################################

resource "google_container_node_pool" "pools" {
  for_each = {
    for combo in flatten([
      for cluster_name, cluster in var.gke_clusters : [
        for np_name, pool in cluster.node_pools : {
          cluster_name = cluster_name
          pool_name    = np_name
          settings     = pool
          cluster      = cluster
        }
      ]
    ]) : "${combo.cluster_name}-${combo.pool_name}" => combo
  }

  name           = each.value.pool_name
  cluster        = google_container_cluster.gke[each.value.cluster_name].name
  location       = each.value.cluster.location_type == "zonal" ? each.value.cluster.zones[0] : each.value.cluster.region
  node_locations = each.value.cluster.location_type == "zonal" ? each.value.cluster.zones : null


  node_count = each.value.settings.node_count

  autoscaling {
    min_node_count = each.value.settings.min_nodes
    max_node_count = each.value.settings.max_nodes
  }

  management {
    auto_upgrade = each.value.settings.auto_upgrade
    auto_repair  = each.value.settings.auto_repair
  }

  upgrade_settings {
    max_surge       = each.value.settings.max_surge
    max_unavailable = each.value.settings.max_unavailable
  }

  node_config {
    machine_type = each.value.settings.machine_type
    disk_size_gb = each.value.settings.disk_size_gb
    image_type   = each.value.settings.image_type

    disk_type = each.value.settings.disk_type

    service_account = each.value.settings.service_account
    oauth_scopes    = each.value.settings.oauth_scopes

    reservation_affinity {
      consume_reservation_type = "ANY_RESERVATION"
    }

    spot = each.value.settings.provisioning_model == "SPOT"
  }
}
