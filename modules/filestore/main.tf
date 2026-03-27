resource "google_filestore_instance" "filestore" {
  for_each = var.filestores
  name     = each.value.filestore_name
  project  = var.project_id
  location = each.value.zone
  tier     = each.value.tier
  file_shares {
    capacity_gb = each.value.filestore_size_gb
    name        = each.value.file_share_name
  }
  networks {
    network           = each.value.vpc_name
    modes             = ["MODE_IPV4"]
    reserved_ip_range = each.value.reserved_ip_range
  }
}