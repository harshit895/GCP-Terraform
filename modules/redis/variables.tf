variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "redis_clusters" {
  description = "Map of Redis cluster definitions"
  type = map(object({
    name                    = string
    region                  = string
    shard_count             = number # Number of shards
    replica_count           = optional(number, 1)
    node_type               = optional(string, "REDIS_SHARED_CORE_NANO")
    authorization_mode      = optional(string, "AUTH_MODE_DISABLED")
    transit_encryption_mode = optional(string, "TRANSIT_ENCRYPTION_MODE_DISABLED")
    network                 = string # PSC consumer network self_link
    subnets                 = list(string)

    # Optional zone distribution
    zone_distribution = optional(object({
      mode = string           # MULTI_ZONE | SINGLE_ZONE
      zone = optional(string) # required if SINGLE_ZONE
    }), null)

    persistence_config = optional(object({
      mode = string # DISABLED | RDB
      rdb_config = optional(object({
        rdb_snapshot_period = string
      }))
    }))

    # Optional Redis configuration map
    redis_configs = optional(map(string), {})

  }))
}
