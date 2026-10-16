provider "volcenginecc" {
  region = var.region
}

module "cloud_connect_network" {
  source  = "terraform-volcenginecc-modules/cloud-connect-network/volcenginecc"
  version = "~> 1.0"

  name         = "group-multi-region-ccn"
  description  = "Multi-region VPC connectivity with dedicated-line and VPN access"
  asn          = 4200065000
  project_name = "default"

  vpc_attachments = {
    primary = {
      vpc_id = var.primary_vpc_id
      attach_points = [{
        subnet_id = var.primary_attachment_subnet_id
        zone_id   = var.primary_attachment_zone_id
      }]
      name                       = "primary-vpc"
      auto_publish_route_enabled = false
    }
    branch = {
      vpc_id = var.branch_vpc_id
      attach_points = [{
        subnet_id = var.branch_attachment_subnet_id
        zone_id   = var.branch_attachment_zone_id
      }]
      name = "branch-vpc"
    }
  }

  direct_connect_gateway_attachments = {
    headquarters = {
      direct_connect_gateway_id = var.direct_connect_gateway_id
      name                      = "headquarters-dcg"
    }
  }

  route_tables = {
    production = {
      name        = "production"
      description = "Production forwarding policy"
    }
  }

  vpn_attachments = {
    disaster-recovery = {
      vpn_connection_id                 = var.vpn_connection_id
      zone_id                           = var.vpn_zone_id
      route_table_key                   = "production"
      health_check_revoke_route_enabled = true
      name                              = "dr-vpn"
    }
  }

  peer_attachments = {
    remote-region = {
      peer_transit_router_id        = var.peer_transit_router_id
      peer_transit_router_region_id = var.peer_transit_router_region_id
      bandwidth_package_key         = "china-to-asia"
      bandwidth                     = 10
      name                          = "remote-region-peer"
    }
  }

  route_table_associations = {
    primary = {
      route_table_key = "production"
      attachment_key  = "primary"
    }
    branch = {
      route_table_key = "production"
      attachment_key  = "branch"
    }
    remote-region = {
      route_table_key = "production"
      attachment_key  = "remote-region"
    }
  }

  route_table_propagations = {
    primary = {
      route_table_key = "production"
      attachment_key  = "primary"
    }
    branch = {
      route_table_key = "production"
      attachment_key  = "branch"
    }
    remote-region = {
      route_table_key = "production"
      attachment_key  = "remote-region"
    }
  }

  route_entries = {
    branch-vpc = {
      route_table_key         = "production"
      destination_cidr_block  = "10.20.0.0/16"
      next_hop_type           = "Attachment"
      next_hop_attachment_key = "branch"
      name                    = "to-branch"
    }
    headquarters = {
      route_table_key         = "production"
      destination_cidr_block  = "172.16.0.0/16"
      next_hop_type           = "Attachment"
      next_hop_attachment_key = "headquarters"
      name                    = "to-headquarters"
    }
    remote-region = {
      route_table_key         = "production"
      destination_cidr_block  = var.peer_vpc_cidr_block
      next_hop_type           = "Attachment"
      next_hop_attachment_key = "remote-region"
      name                    = "to-remote-region"
    }
  }

  bandwidth_packages = {
    china-to-asia = {
      name                           = "china-to-asia"
      local_geographic_region_set_id = "China"
      peer_geographic_region_set_id  = "Asia"
      bandwidth                      = 10
      billing_type                   = 1
      period                         = 1
      period_unit                    = "Month"
      renew_type                     = "NoRenew"
    }
  }

  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
    Topology    = "multi-region"
  }
}
