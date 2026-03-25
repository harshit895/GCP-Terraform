variable "project_id" {
  type        = string
  description = "Name of the Project"
}

variable "routing_mode" {
  type    = string
  default = "GLOBAL"
}

variable "region" {
  type    = string
  default = null
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "nat_logging" {
  type    = bool
  default = false
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
  default     = "test-vpc"
}


variable "instances" {
  description = "Map of instance definitions. key => {name, machine_type, disk_image, subnet, tags, metadata, service_account_email, assign_external_ip (optional)}"
  type = map(object({
    name                    = string
    machine_type            = string
    boot_disk_type          = optional(string)
    disk_image              = string
    subnet_name             = string
    zone                    = string
    tags                    = optional(list(string), [])
    metadata                = optional(map(string), {})
    assign_external_ip      = optional(bool, false)
    boot_disk_size_gb       = optional(number, 50)
    private_ip              = optional(string)
    custom_private_ip       = bool
    hostname                = optional(string)
    set_hostname            = bool
    vm_username             = optional(string)
    auto_delete_bootdisk    = optional(bool, true)
    enable_additional_disks = optional(bool, false)
    additional_disks = optional(list(object({
      name = string
      size = number
      type = string
    })), [])
  }))
  default = {
    private-01 = {
      name              = "app-01"
      machine_type      = "e2-medium"
      disk_image        = "projects/debian-cloud/global/images/family/debian-12"
      subnet_name       = "private-1"
      zone              = "us-central1-a"
      tags              = ["private-vpc-access"]
      private_ip        = "10.0.0.1"
      custom_private_ip = false
      hostname          = "default"
      set_hostname      = false
    }
  }
}

variable "peerings" {
  description = "Peering configuration object"
  type = object({
    enabled = bool
    connections = optional(list(object({
      name                                = string
      network_self                        = string
      peer_network                        = string
      stack_type                          = string
      update_strategy                     = string
      import_subnet_routes_with_public_ip = optional(bool, true)
      export_routes                       = optional(bool, true)
      import_routes                       = optional(bool, true)
    })), [])
  })
  default = null
}

variable "network_policy" {
  type    = bool
  default = true
}

variable "filestore_name" {
  type    = string
  default = "default"
}

variable "tier" {
  type    = string
  default = "STANDARD"
}

variable "filestore_size_gb" {
  type    = number
  default = 1024
}

variable "reserved_ip_range" {
  type    = string
  default = "10.20.30.0/29"
}

variable "db_flags" {
  type    = map(string)
  default = {}
}

variable "enable_private_nodes" {
  type    = bool
  default = false
}
variable "enable_private_endpoint" {
  type    = bool
  default = false
}
variable "master_ipv4_cidr" {
  type    = string
  default = "172.16.0.0/28"
}
variable "master_authorized_ranges" {
  type    = list(string)
  default = []
}

variable "vm_backup_plan" {
  type        = string
  description = "Backup plan name"
  default     = "default"
}

variable "enable_backup_plan" {
  type        = bool
  default     = false
  description = "Enable/Disable backup plan"
}

variable "file_share_name" {
  type    = string
  default = "file_share"
}

variable "filestores" {
  description = "Map of instance definitions. key => {name, machine_type, disk_image, subnet, tags, metadata, service_account_email, assign_external_ip (optional)}"
  type = map(object({
    filestore_name    = optional(string)
    tier              = optional(string)
    filestore_size_gb = optional(number)
    reserved_ip_range = optional(string)
    file_share_name   = optional(string)
    zone              = optional(string)
    vpc_name          = optional(string)
  }))
  default = {
    filestore1 = {
      filestore_name    = "dem-filestore"
      tier              = "BASIC_HDD"
      filestore_size_gb = 1024
      reserved_ip_range = "10.20.30.0/29"
      file_share_name   = "test"
      zone              = "us-central1-a"
      vpc_name          = "default"
    }
  }
}

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
  default = {
    db = {
      database_version = "POSTGRES_15"
      tier             = "db-f1-micro"
      disk_size_gb     = 10
      disk_type        = "PD_SSD"
      region           = "asia-south1"
      network          = "projects/elliott-ai/global/networks/fdfss"

      settings = {
        db_user           = "orders_user"
        db_name           = "orders"
        availability_type = "REGIONAL"
        backup_enabled    = true
      }

      db_flags = {
        max_connections = "200"
      }
      psc_connection = "psa-range-1"
    }
  }
}

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
    master_ipv4_cidr_block            = optional(string, null)
    enable_private_nodes              = bool
    enable_private_endpoint           = bool
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
  default = null
}

variable "enable_proxy_subnets" {
  type        = bool
  default     = false
  description = "Enable creation of proxy-only subnets for load balancing"
}

variable "redis_clusters" {
  description = "Map of Redis cluster definitions"
  default = null
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

variable "vpcs" {
  description = "Map of VPCs (key = vpc_name)"
  type = map(object({
    project      = string
    routing_mode = string
    region       = string
  }))
  default = {}
}

variable "subnets" {
  description = "Subnets per VPC: subnets[vpc_name][subnet_name] = config"
  type = map(map(object({
    cidr             = string
    region           = optional(string)
    private_access   = optional(bool, true)
    enable_secondary = optional(bool, true)
    pod_cidr_range   = optional(string)
    svc_cidr_range   = optional(string)
  })))
  default = {}
}


variable "proxy_subnets" {
  description = "Proxy subnets per VPC"
  type = map(map(object({
    cidr    = string
    region  = string
    purpose = string
  })))
  default = {}
}

variable "private_service_ranges" {
  description = "Private service ranges per VPC"
  type = map(object({
    enabled = bool
    psa = list(object({
      name                           = string
      ip_address                     = string
      private_services_prefix_length = number
    }))
  }))
  default = {}
}

variable "firewall_rules" {
  description = "Firewall rules per VPC"
  type = map(object({
    enabled = bool
    rules = list(object({
      name        = string
      direction   = string
      priority    = optional(number, 1000)
      ranges      = list(string)
      target_tags = list(string)
      protocol    = string
      ports       = list(string)
    }))
  }))
  default = {}
}
