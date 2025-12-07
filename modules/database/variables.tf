variable "project" { type = string }
variable "db_instances" {
  description = "Map of Cloud SQL instances"
  type = map(object({
    database_version = string
    tier             = string
    disk_size_gb     = number
    disk_type        = optional(string)
    network          = string
    region           = string
    ssl_mode         = optional(string, "ALLOW_UNENCRYPTED_AND_ENCRYPTED")

    settings = object({
      availability_type                  = optional(string, "ZONAL")
      backup_enabled                     = optional(bool, true)
      point_in_time_recovery_enabled     = optional(bool, false)
      binary_log_enabled                 = optional(bool, false)
      edition                            = optional(string, "ENTERPRISE")
      db_user                            = optional(string, "appuser")
      db_name                            = optional(string, "appdb")
      location_primary_preference_zone   = optional(string, "us-central1-a")
      location_secondary_preference_zone = optional(string, "us-central1-b")
    })

    db_flags       = optional(map(string), {})
    psc_connection = optional(any)
  }))
}
