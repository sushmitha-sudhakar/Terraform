terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "Terraform-cert-sush"

    workspaces {
      name = "Terraform-new"
    }
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.72.0"
    }
  }
}

locals {
  project_name = "Terraform"
}
