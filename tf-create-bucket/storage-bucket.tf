
provider "google" {
  # Project should be set by running    gcloud config set project main-demo-468721-a9
  # However, the google provider does not pick this value up, so we have to hard-code.
  project = "main-demo-468721-a9"
  # The google provider also does not pick up the region.
}

variable "gcp_region" {
  description = "The GCP region to create resources in"
  type        = string
  default     = "us-central1" # Or your desired default
}

# provide a default value of 'demo" for the bucket name:
variable "bucket_name" {
  description = "Cloud Storage bucket name"
  type        = string
  default     = "kennyk-demo"
}


resource "google_storage_bucket" "bucket" {
  name     = var.bucket_name
  location = var.gcp_region
  uniform_bucket_level_access = true
}