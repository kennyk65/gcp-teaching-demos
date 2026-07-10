## Terraform GKE + nginx LoadBalancer

This Terraform template creates:
- A GKE Autopilot cluster
- An nginx deployment in Kubernetes
- A LoadBalancer service exposing nginx on port 80

### Prerequisites
- Terraform >= 1.5
- gcloud CLI installed.
- A GCP project with GKE API enabled.

## Setup

1. Authenticate with gcloud
    ```
    # Authenticates the gcloud CLI itself
    gcloud auth login --no-launch-browser
    # Generates Application Default Credentials (ADC) so Terraform can authenticate
    gcloud auth application-default login --no-launch-browser
    ```
1. Adjust region and project.

    Because the Terraform Google provider sucks, it cannot resolve the default region or project.  You'll have to hard-code these in the provider element:
    
    ```
        provider "google" {
        # Unfortunately, the google provider is not intelligent enough to pull project and region from gcloud.  
        project = "REPLACE-ME"
        region  = "REPLACE-ME"    
        }
    ```
    
2. Initialize and apply:

   ```powershell
   terraform init
   terraform apply
   ```
    Expect the cluster creation to take at least 5 minutes.

5. Get the URL:

   ```powershell
   terraform output nginx_service_url
   ```

If the output is `pending`, wait a minute and run the output command again while the external load balancer is provisioning.

## Demo
