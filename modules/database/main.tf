resource "google_sql_database_instance" "db" {
  for_each = var.db_instances

  name                = each.key
  project             = var.project
  region              = each.value.region
  database_version    = each.value.database_version
  deletion_protection = false
  settings {
    tier              = each.value.tier
    disk_size         = each.value.disk_size_gb
    disk_type         = each.value.disk_type
    edition           = each.value.settings.edition
    availability_type = each.value.settings.availability_type

    ip_configuration {
      private_network = each.value.network
      ipv4_enabled    = false
      ssl_mode        = each.value.ssl_mode
    }

    backup_configuration {
      enabled                        = each.value.settings.backup_enabled
      point_in_time_recovery_enabled = each.value.settings.point_in_time_recovery_enabled
      binary_log_enabled             = each.value.settings.binary_log_enabled
    }

    location_preference {
      zone           = each.value.settings.location_primary_preference_zone
      secondary_zone = each.value.settings.location_secondary_preference_zone
    }

    dynamic "database_flags" {
      for_each = each.value.db_flags
      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }
  }
}

resource "random_password" "db_password" {
  for_each = var.db_instances

  length           = 32
  special          = true
  override_special = "!@#%&*()-_=+[]{}<>:?"
}

resource "google_secret_manager_secret" "db_secret" {
  for_each = var.db_instances

  secret_id = "${each.key}-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_secret_version" {
  for_each = var.db_instances

  secret      = google_secret_manager_secret.db_secret[each.key].id
  secret_data = random_password.db_password[each.key].result
}

resource "google_sql_user" "db_user" {
  for_each = var.db_instances

  name     = each.value.settings.db_user
  instance = google_sql_database_instance.db[each.key].name
  password = google_secret_manager_secret_version.db_secret_version[each.key].secret_data
  project  = var.project

  host = can(regex("MYSQL", each.value.database_version)) ? "%" : null
}


