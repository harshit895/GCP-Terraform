resource "google_redis_cluster" "this" {
  for_each = var.redis_clusters

  project = var.project_id
  region  = each.value.region
  name    = each.value.name

  # Required fields
  shard_count   = each.value.shard_count
  replica_count = each.value.replica_count

  node_type = each.value.node_type

  authorization_mode      = each.value.authorization_mode
  transit_encryption_mode = each.value.transit_encryption_mode

  # PSC config(s) — MUST provide at least network
  dynamic "psc_configs" {
    for_each = [for net in [each.value.network] : net]
    content {
      network = psc_configs.value
    }
  }

  # Zone distribution block
  dynamic "zone_distribution_config" {
    for_each = each.value.zone_distribution == null ? [] : [each.value.zone_distribution]
    content {
      mode = zone_distribution_config.value.mode
      zone = lookup(zone_distribution_config.value, "zone", null)
    }
  }

  dynamic "persistence_config" {
    for_each = lookup(each.value, "persistence_config", null) != null ? [1] : []
    content {
      mode = each.value.persistence_config.mode

      dynamic "rdb_config" {
        for_each = lookup(each.value.persistence_config, "rdb_config", null) != null ? [1] : []
        content {
          rdb_snapshot_period = each.value.persistence_config.rdb_config.rdb_snapshot_period
        }
      }
    }
  }

  redis_configs = each.value.redis_configs

}

resource "google_network_connectivity_service_connection_policy" "gke_policy" {
  for_each    = var.redis_clusters
  name        = each.value.name
  location    = each.value.region
  description = "Policy for GKE PSC connections to Memorystore Redis"

  network = each.value.network

  psc_config {
    subnetworks = each.value.subnets
    limit       = 10
  }

  service_class = "gcp-memorystore-redis" # For Redis Cluster
}