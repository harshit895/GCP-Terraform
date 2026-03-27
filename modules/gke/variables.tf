# variable "project_id" {
#   type        = string
#   description = "Name of the Project"
# }
variable "gke_clusters" {
  type = map(object({
    cluster_name                  = string
    location_type                 = string
    region                        = string
    zones                         = list(string)
    kubernetes_version            = string
    release_channel               = string
    network                       = string
    subnetwork                    = string
    maintenance_window            = string
    pods_secondary_range_name     = string
    services_secondary_range_name = string

    # Private cluster new settings
    enable_private_nodes              = bool
    enable_private_endpoint           = bool
    master_ipv4_cidr_block            = optional(string, null)
    enable_master_authorized_networks = bool
    authorized_networks = list(object({
      name = string
      cidr = string
    }))

    # All previous vars preserved
    enable_security_posture      = bool
    enable_shielded_nodes        = bool
    enable_gcsfuse               = bool
    enable_filestore             = bool
    enable_backup                = bool
    enable_lustre_csi_driver     = bool
    enable_legacy_abac           = bool
    enable_binary_authorization  = bool
    enable_logging_components    = list(string)
    enable_monitoring_components = list(string)
    enable_cost_allocation       = bool
    enable_secret_manager        = bool
    project_id                   = string

    node_pools = map(object({
      node_count         = number
      min_nodes          = number
      max_nodes          = number
      auto_upgrade       = bool
      auto_repair        = bool
      max_surge          = number
      max_unavailable    = number
      machine_type       = string
      disk_size_gb       = number
      disk_type          = string
      image_type         = string
      service_account    = string
      oauth_scopes       = list(string)
      provisioning_model = string
    }))
  }))
}
