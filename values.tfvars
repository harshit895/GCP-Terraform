### General Variables ###
project_id = "fdfsf-ai"
region     = "us-central1"


# ## Network Variables ###
vpc_name = "ghfdgsdf"
subnets = {
  "private-1" = {
    cidr             = "10.10.1.0/24"
    private_access   = true
    enable_secondary = true
    pod_cidr_range   = "10.20.0.0/20"
    svc_cidr_range   = "10.30.0.0/20"
  }
  "private-2" = {
    cidr             = "10.10.2.0/24"
    private_access   = true
    enable_secondary = false
  }

  "public-1" = {
    cidr             = "10.10.100.0/24"
    private_access   = false
    enable_secondary = false
  }
}
private_service_ranges = {
  enabled = false
  psa = [
    {
      name                           = "psa-range-mysql"
      ip_address                     = "10.10.3.0"
      private_services_prefix_length = 24
    }
  ]
}

enable_proxy_subnets = false
proxy_subnets = {
  "proxy-1" = {
    cidr    = "10.10.200.0/26"
    region  = "us-central1"
    purpose = "REGIONAL_MANAGED_PROXY"
  }
  "proxy-2" = {
    cidr    = "10.10.201.0/26"
    region  = "asia-south1"
    purpose = "INTERNAL_HTTPS_LOAD_BALANCER"
  }
}


firewall_rules = {
  enabled = true
  rules = [
    {
      name        = "allow-internal"
      direction   = "INGRESS"
      ranges      = ["10.0.0.0/16"]
      target_tags = []
      ports       = ["22", "80"]
      protocol    = "tcp"
    },
    {
      name        = "allow-public"
      direction   = "INGRESS"
      ranges      = ["0.0.0.0/0"]
      target_tags = ["bastion-access"]
      ports       = ["22"]
      protocol    = "tcp"
    }
  ]
}
peerings = {
  enabled = true
  connections = [
    {
      name                                = "vpctovpc"
      network_self                        = "https://www.googleapis.com/compute/v1/projects/elliott-ai/global/networks/ghfdgsdf"
      peer_network                        = "https://www.googleapis.com/compute/v1/projects/elliott-ai/global/networks/default"
      stack_type                          = "IPV4_ONLY"
      update_strategy                     = "INDEPENDENT"
      import_subnet_routes_with_public_ip = true
    },
    {
      name                                = "dsfds"
      network_self                        = "https://www.googleapis.com/compute/v1/projects/elliott-ai/global/networks/ghfdgsdf"
      peer_network                        = "https://www.googleapis.com/compute/v1/projects/elliott-ai/global/networks/default"
      stack_type                          = "IPV4_ONLY"
      update_strategy                     = "INDEPENDENT"
      import_subnet_routes_with_public_ip = true
    },
  ]
}

### Compute Variables ####
instances = {
  private-01 = {
    name                    = "app-01"
    machine_type            = "e2-medium"
    disk_image              = "projects/debian-cloud/global/images/family/debian-12"
    boot_disk_type          = "pd-balanced"
    boot_disk_size_gb       = 20
    auto_delete_bootdisk    = true
    subnet_name             = "https://www.googleapis.com/compute/v1/projects/elliott-ai/regions/us-central1/subnetworks/default"
    zone                    = "us-central1-a"
    tags                    = ["private-vpc-access"]
    custom_private_ip       = true
    private_ip              = "10.128.0.54"
    set_hostname            = true
    hostname                = "myhostsd.fdsd.com"
    vm_username             = "fdsfs"
    enable_additional_disks = false

  }
  public-01 = {
    name                    = "bastion-01"
    machine_type            = "e2-medium"
    disk_image              = "projects/debian-cloud/global/images/family/debian-12"
    boot_disk_type          = "pd-standard"
    auto_delete_bootdisk    = true
    subnet_name             = "https://www.googleapis.com/compute/v1/projects/elliott-ai/regions/us-central1/subnetworks/default"
    assign_external_ip      = "true"
    zone                    = "us-central1-b"
    tags                    = ["bastion-access"]
    boot_disk_size_gb       = 11
    custom_private_ip       = false
    set_hostname            = false
    vm_username             = "hgfhd"
    enable_additional_disks = true
    additional_disks = [
      { name = "data-disk1", size = 10, type = "pd-balanced" },
      { name = "data-disk2", size = 15, type = "pd-ssd" }
    ]
  }
}
enable_backup_plan = true
vm_backup_plan     = "projects/elliott-ai/locations/us-central1/backupPlans/fsdf"


# ### CloudSQL Variables
db_instances = {
  auth-db = {
    database_version = "MYSQL_8_0_41"
    tier             = "db-g1-small"
    disk_size_gb     = 30
    disk_type        = "PD_SSD"
    region           = "us-central1"
    network          = "projects/elliott-ai/global/networks/ghfdgsdf"
    ssl_mode         = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"

    settings = {
      db_user                            = "auth_user"
      availability_type                  = "REGIONAL"
      edition                            = "ENTERPRISE"
      backup_enabled                     = true
      binary_log_enabled                 = true
      location_primary_preference_zone   = "us-central1-a"
      location_secondary_preference_zone = "us-central1-b"
    }

    db_flags = {
      max_connections                 = "200"
      lower_case_table_names          = "1"
      log_bin_trust_function_creators = "on"
    }
    psc_connection = "psa-range-mysql"
  }
}

# ### GKE ####

gke_clusters = {
  cluster-1 = {
    cluster_name  = "gke-primary"
    location_type = "zonal"
    region        = "us-central1"
    zones         = ["us-central1-a", "us-central1-c"]

    kubernetes_version = "1.34.1-gke.3355002"
    release_channel    = "REGULAR"

    # VPC + Subnet
    network            = "projects/elliott-ai/global/networks/ghfdgsdf"
    subnetwork         = "projects/elliott-ai/regions/us-central1/subnetworks/private-1"
    maintenance_window = "2025-12-18T02:00:00Z"

    # Optional – depends on your updated network module
    pods_secondary_range_name     = "private-1-pods"
    services_secondary_range_name = "private-1-services"

    # Private cluster
    enable_private_endpoint           = false
    enable_private_nodes              = true
    master_ipv4_cidr_block            = "172.16.0.0/28"
    enable_master_authorized_networks = false
    authorized_networks = [
      {
        name = "office"
        cidr = "10.128.2.0/24"
      },
      {
        name = "home"
        cidr = "10.128.0.0/24"
      }
    ]

    # Standard feature flags
    enable_security_posture      = true
    enable_shielded_nodes        = true
    enable_gcsfuse               = true
    enable_filestore             = false
    enable_backup                = true
    enable_lustre_csi_driver     = false
    enable_legacy_abac           = false
    enable_binary_authorization  = false
    enable_logging_components    = ["SYSTEM_COMPONENTS", "WORKLOADS"]
    enable_monitoring_components = ["SYSTEM_COMPONENTS", "SCHEDULER", "CONTROLLER_MANAGER"]
    enable_cost_allocation       = true
    enable_secret_manager        = true

    project_id = "elliott-ai"

    node_pools = {
      general = {
        node_count         = 1 # per zone, if 2 zones then total (3x2=6) nodes will be 6
        min_nodes          = 1
        max_nodes          = 3
        auto_upgrade       = true
        auto_repair        = true
        max_surge          = 1
        max_unavailable    = 0
        machine_type       = "e2-standard-4"
        disk_size_gb       = 30
        disk_type          = "pd-ssd"
        image_type         = "COS_CONTAINERD"
        service_account    = "738265634986-compute@developer.gserviceaccount.com"
        oauth_scopes       = ["https://www.googleapis.com/auth/cloud-platform"]
        provisioning_model = "STANDARD"
      }

      spot = {
        node_count         = 3 # per zone, if 2 zones then total (3x2=6) nodes will be 6
        min_nodes          = 0
        max_nodes          = 3
        auto_upgrade       = true
        auto_repair        = true
        max_surge          = 1
        max_unavailable    = 0
        machine_type       = "e2-standard-2"
        disk_size_gb       = 50
        disk_type          = "pd-ssd"
        image_type         = "COS_CONTAINERD"
        service_account    = "738265634986-compute@developer.gserviceaccount.com"
        oauth_scopes       = ["https://www.googleapis.com/auth/cloud-platform"]
        provisioning_model = "SPOT"
      }
    }
  }
}


# ### Filestore ###
filestores = {
  filestore1 = {
    filestore_name    = "dem-filestore"
    tier              = "BASIC_HDD"
    filestore_size_gb = 1536
    reserved_ip_range = "10.20.30.0/29"
    file_share_name   = "test"
    zone              = "us-central1-a"
    vpc_name          = "default"
  }
  filestore2 = {
    filestore_name    = "filedsadstore"
    tier              = "BASIC_HDD"
    filestore_size_gb = 1024
    vpc_name          = "default"
    reserved_ip_range = "10.20.10.0/29"
    file_share_name   = "dssad"
    zone              = "us-central1-a"
  }
}


#### Redis #####

redis_clusters = {
  app = {
    name                    = "cache-app"
    region                  = "us-central1"
    shard_count             = 3
    replica_count           = 1
    node_type               = "REDIS_SHARED_CORE_NANO"
    authorization_mode      = "AUTH_MODE_IAM_AUTH"
    transit_encryption_mode = "TRANSIT_ENCRYPTION_MODE_SERVER_AUTHENTICATION"
    network                 = "projects/elliott-ai/global/networks/ghfdgsdf"
    subnets                 = ["projects/elliott-ai/regions/us-central1/subnetworks/private-1"]

    zone_distribution = {
      mode = "MULTI_ZONE"
    }

    persistence_config = {
      mode = "RDB"
      rdb_config = {
        rdb_snapshot_period = "TWELVE_HOURS"
      }
    }

    redis_configs = {
      "maxmemory-policy" = "allkeys-lru"
    }

  }

  # auth-cache = {
  #   name       = "cache-auth"
  #   region     = "us-central1"
  #   shard_count  = 2
  #   replica_count = 1
  #   network = "projects/elliott-ai/global/networks/ghfdgsdf"
  #   zone_distribution = {
  #     mode = "SINGLE_ZONE"
  #     zone = "us-central1-c"
  #   }
  # }
}
