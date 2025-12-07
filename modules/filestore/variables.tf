variable "project_id" { type = string }
variable "network" { type = string }
variable "filestores" {
  description = "Map of instance definitions. key => {name, machine_type, disk_image, subnet, tags, metadata, service_account_email, assign_external_ip (optional)}"
  type = map(object({
    filestore_name    = optional(string)
    tier              = optional(string)
    filestore_size_gb = optional(number)
    reserved_ip_range = optional(string)
    file_share_name   = optional(string)
    zone              = optional(string)
  }))
}