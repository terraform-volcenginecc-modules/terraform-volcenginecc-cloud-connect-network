provider "volcenginecc" {
  region = var.region
}

module "cloud_connect_network" {
  source  = "terraform-volcenginecc-modules/cloud-connect-network/volcenginecc"
  version = "~> 1.0"

  name        = "basic-ccn"
  description = "Basic VPC connectivity through a Transit Router"

  vpc_attachments = {
    workload = {
      vpc_id = var.vpc_id
      attach_points = [{
        subnet_id = var.attachment_subnet_id
        zone_id   = var.attachment_zone_id
      }]
      name = "workload-vpc"
    }
  }

  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}
