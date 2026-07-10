terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.35"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
  }
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "demo-gke-cluster"
}

variable "namespace" {
  description = "Kubernetes namespace for the nginx deployment"
  type        = string
  default     = "default"
}

data "google_client_config" "current" {}

provider "google" {
  # Unfortunately, the google provider is not intelligent enough to pull project and region from gcloud.  
  project = "demoproject-468012"
  region  = "us-south1"    
}

resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  enable_autopilot = true
  deletion_protection = false
}

# The kubernetes provider (below) works best on updates when it is explicitly provided with the actual 
# cluster's name and location.  Otherwise it defaults to localhost and no updates are possible.
data "google_container_cluster" "gke" {
  name     = google_container_cluster.gke.name
  location = google_container_cluster.gke.location
  depends_on = [google_container_cluster.gke]
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.gke.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx"
    namespace = var.namespace
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:stable"

          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [google_container_cluster.gke]
}

resource "kubernetes_service" "nginx_lb" {
  metadata {
    name      = "nginx-lb"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.nginx]
}

locals {
  service_ip       = try(kubernetes_service.nginx_lb.status[0].load_balancer[0].ingress[0].ip, null)
  service_hostname = try(kubernetes_service.nginx_lb.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.gke.name
}

output "gke_cluster_location" {
  description = "GKE cluster location"
  value       = google_container_cluster.gke.location
}

output "nginx_service_external_address" {
  description = "External IP or hostname for the nginx LoadBalancer service"
  value       = coalesce(local.service_ip, local.service_hostname, "pending")
}

output "nginx_service_url" {
  description = "HTTP URL for the nginx service"
  value       = local.service_ip != null ? "http://${local.service_ip}" : local.service_hostname != null ? "http://${local.service_hostname}" : "pending"
}
