
# To Run:
# 1. Use gcloud to login to your account with an incognito browser:  gcloud auth application-default login --no-launch-browser
# 2. terraform init
# 3. terraform apply
# 4. Look at the output for the web_link and click it to see your web page
# 5. terraform destroy (to clean up resources when done)

variable "project_id" {
  description = "The ID of the project where the VM will be created"
  type        = string
  default     = "demoproject-468012" 
}

variable "region" {
  description = "The region for the resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone within the region"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Name of the VM instance"
  type        = string
  default     = "demo-vm-instance"
}

variable "machine_type" {
  description = "The machine type to use for the VM"
  type        = string
  default     = "e2-medium"
}

variable "vpc_network" {
  description = "The name of the VPC network"
  type        = string
  default     = "default"
}

variable "vpc_subnet" {
  description = "The name of the subnet"
  type        = string
  default     = "default"
}

variable "image" {
  description = "The source image for the boot disk"
  type        = string
  default     = "debian-cloud/debian-11"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = var.vpc_subnet
    access_config {} 
  }

  # Using a heredoc but being very careful with the shebang
  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    echo "<h1>Hello World from GCP VM: $(hostname)</h1>" > /var/www/html/index.html
    systemctl restart apache2
  EOT
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-traffic"
  network = var.vpc_network

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Only apply this rule to instances with the "http-server" tag
  target_tags   = ["http-server"]
  source_ranges = ["0.0.0.0/0"]
}


output "instance_self_link" {
  value = google_compute_instance.vm_instance.self_link
}

# --- The User-Friendly Output ---
output "web_link" {
  description = "Click this link to view your web page"
  value       = "http://${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip}"
}
