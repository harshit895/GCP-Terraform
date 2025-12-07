terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.12.0"
    }
  }
  backend "gcs" {
    bucket = "TF_STATE_BUCKET"
    prefix = "terraform/state"
  }

}

provider "google" {
  project = var.project_id
  region  = var.region
}
