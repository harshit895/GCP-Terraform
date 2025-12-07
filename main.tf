module "network" {
  source                 = "./modules/network"
  project                = var.project_id
  vpc_name               = var.vpc_name
  subnets                = var.subnets
  region                 = var.region
  firewall_rules         = var.firewall_rules
  peerings               = var.peerings
  private_service_ranges = var.private_service_ranges
  proxy_subnets          = var.proxy_subnets
  enable_proxy_subnets   = var.enable_proxy_subnets
}

module "compute" {
  source                 = "./modules/compute"
  project                = var.project_id
  region                 = var.region
  instances              = var.instances
  vm_backup_plan         = var.vm_backup_plan
  enable_backup_plan     = var.enable_backup_plan
  enable_additional_disk = var.enable_additional_disk
}

module "cloudsql" {
  source  = "./modules/database"
  project = var.project_id

  db_instances = var.db_instances
}

module "gke" {
  source = "./modules/gke"
  gke_clusters = var.gke_clusters
}

module "filestore" {
  source = "./modules/filestore"

  project_id = var.project_id
  filestores = var.filestores
  network    = module.network.vpc_id
}
