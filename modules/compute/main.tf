resource "google_service_account" "compute_sa" {
  account_id   = "preprod-wallyt-compute-sa"
  display_name = "Compute service account for instances"
  project      = var.project
}

locals {
  disks_map = {
    for d in flatten([
      for vm_key, vm in var.instances :
      (
        lookup(vm, "enable_additional_disks", false)
        ? [
          for disk in vm.additional_disks :
          {
            vm_key = vm_key
            zone   = vm.zone
            name   = disk.name
            size   = disk.size
            type   = disk.type
          }
        ]
        : []
      )
    ]) :
    "${d.vm_key}-${d.name}" => d
  }
}

resource "google_compute_instance" "vm" {
  for_each     = var.instances
  name         = each.value.name
  project      = var.project
  zone         = each.value.zone
  machine_type = each.value.machine_type

  boot_disk {
    auto_delete = each.value.auto_delete_bootdisk
    source      = google_compute_disk.boot_disk[each.key].self_link
  }
  hostname = lookup(each.value, "set_hostname", false) ? each.value.hostname : null

  dynamic "attached_disk" {
    for_each = (
      lookup(each.value, "enable_additional_disks", false)
      ? [
        for k, d in local.disks_map :
        d
        if d.vm_key == each.key
      ]
      : []
    )

    content {
      source      = google_compute_disk.additional_disk["${each.key}-${attached_disk.value.name}"].id
      mode        = "READ_WRITE"
      device_name = attached_disk.value.name
    }
  }

  network_interface {
    subnetwork = each.value.subnet_name

    # Only add external IP if assign_external_ip = true
    dynamic "access_config" {
      for_each = lookup(each.value, "assign_external_ip", false) ? [1] : []
      content {}
    }
    network_ip = lookup(each.value, "custom_private_ip", false) ? each.value.private_ip : null


  }
  tags = each.value.tags

  service_account {
    email  = google_service_account.compute_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  metadata = {
    ssh-keys = "${each.value.vm_username}:${tls_private_key.ssh_key[each.key].public_key_openssh}"
  }

  labels = {
    module = "compute"
  }
}

resource "tls_private_key" "ssh_key" {
  for_each  = var.instances
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_secret_manager_secret" "ssh_key_secret" {
  for_each = var.instances

  secret_id = "${each.key}-ssh-key"
  project   = var.project

  replication {
    user_managed {
      replicas {
        location = "me-central2"
      }
    }
  }
}

resource "google_secret_manager_secret_version" "ssh_key_secret_version" {
  for_each = var.instances

  secret      = google_secret_manager_secret.ssh_key_secret[each.key].id
  secret_data = tls_private_key.ssh_key[each.key].private_key_pem
}

resource "google_compute_disk" "additional_disk" {
  for_each = local.disks_map

  name = each.value.name
  type = each.value.type
  size = each.value.size
  zone = each.value.zone
}

resource "google_compute_disk" "boot_disk" {
  for_each = var.instances

  name  = "${each.value.name}-boot"
  type  = each.value.boot_disk_type
  zone  = each.value.zone
  size  = each.value.boot_disk_size_gb # Can be increased later WITHOUT RECREATE
  image = each.value.disk_image
}

resource "google_backup_dr_backup_plan_association" "backup-plan-association" {
  for_each                   = var.enable_backup_plan ? var.instances : {}
  location                   = var.region
  resource_type              = "compute.googleapis.com/Instance"
  backup_plan_association_id = each.value.name
  resource                   = google_compute_instance.vm[each.key].id
  backup_plan                = var.vm_backup_plan
}
