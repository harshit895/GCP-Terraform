variable "project" { type = string }
variable "region" { type = string }
variable "instances" {
  description = "Map of instance definitions. key => {name, machine_type, disk_image, subnet, tags, metadata, service_account_email, assign_external_ip (optional)}"
  type = map(object({
    name                 = string
    machine_type         = string
    disk_image           = string
    boot_disk_type       = optional(string)
    subnet_name          = string
    zone                 = string
    tags                 = optional(list(string), [])
    metadata             = optional(map(string), {})
    assign_external_ip   = optional(bool, false)
    boot_disk_size_gb    = optional(number, 50)
    private_ip           = optional(string)
    custom_private_ip    = bool
    hostname             = optional(string)
    set_hostname         = bool
    vm_username          = optional(string)
    additional_disk_type = optional(string)
    additional_disk_name = optional(string)
    additional_disk_size = optional(string)
    auto_delete_bootdisk = optional(bool, true)

  }))
}

variable "vm_backup_plan" {
  type        = string
  description = "Backup plan name"
}

variable "enable_backup_plan" {
  type        = bool
  default     = false
  description = "Enable/Disable backup plan"
}

variable "enable_additional_disk" {
  type    = bool
  default = false
}
