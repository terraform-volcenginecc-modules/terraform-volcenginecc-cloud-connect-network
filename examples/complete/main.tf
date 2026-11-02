provider "volcenginecc" {
  region = var.region
}

data "volcenginecc_vpc_subnet" "attachment" {
  for_each = local.vpcs
  id       = each.value.subnet_id
}

data "volcenginecc_vpn_vpn_connection" "this" {
  count = var.vpn_connection_id == null ? 0 : 1
  id    = var.vpn_connection_id
}

locals {
  vpn_enabled      = var.vpn_connection_id != null
  dc_enabled       = var.direct_connect_gateway_id != null
  vpn_remote_cidrs = local.vpn_enabled ? data.volcenginecc_vpn_vpn_connection.this[0].remote_subnet : toset([])
  vpcs = {
    primary = {
      vpc_id    = var.primary_vpc_id
      subnet_id = var.primary_subnet_id
    }
    branch = {
      vpc_id    = var.branch_vpc_id
      subnet_id = var.branch_subnet_id
    }
  }
}

module "cloud_connect_network" {
  source  = "terraform-volcenginecc-modules/cloud-connect-network/volcenginecc"
  version = "~> 1.0"
  
  depends_on = [terraform_data.configuration]

  name         = var.name
  description  = "Multi-region VPC connectivity with optional dedicated-line and VPN access"
  project_name = "default"

  vpc_attachments = {
    for key, vpc in local.vpcs : key => {
      vpc_id = vpc.vpc_id
      attach_points = [{
        subnet_id = vpc.subnet_id
        zone_id   = data.volcenginecc_vpc_subnet.attachment[key].zone_id
      }]
      name                       = "${key}-vpc"
      auto_publish_route_enabled = true
    }
  }

  direct_connect_gateway_attachments = local.dc_enabled ? {
    headquarters = {
      direct_connect_gateway_id = var.direct_connect_gateway_id
      name                      = "headquarters-dcg"
    }
  } : {}

  route_tables = {
    production = {
      name        = "production"
      description = "Production forwarding policy"
    }
  }

  vpn_attachments = local.vpn_enabled ? {
    disaster-recovery = {
      vpn_connection_id = var.vpn_connection_id
      zone_id           = var.vpn_zone_id
      name              = "dr-vpn"
    }
  } : {}

  peer_attachments = {
    remote-region = {
      peer_transit_router_id        = var.peer_transit_router_id
      peer_transit_router_region_id = var.peer_region_id
      bandwidth_package_id          = var.bandwidth_package_id
      bandwidth                     = var.peer_bandwidth
      name                          = "remote-region-peer"
    }
  }

  route_table_associations = merge({
    for key in keys(local.vpcs) : key => { route_table_key = "production", attachment_key = key }
    }, {
    remote-region = { route_table_key = "production", attachment_key = "remote-region" }
    }, local.vpn_enabled ? {
    disaster-recovery = { route_table_key = "production", attachment_key = "disaster-recovery" }
    } : {}, local.dc_enabled ? {
    headquarters = { route_table_key = "production", attachment_key = "headquarters" }
  } : {})

  route_table_propagations = merge({
    for key in keys(local.vpcs) : key => { route_table_key = "production", attachment_key = key }
    }, {
    remote-region = { route_table_key = "production", attachment_key = "remote-region" }
    }, local.dc_enabled ? {
    headquarters = { route_table_key = "production", attachment_key = "headquarters" }
  } : {})

  route_entries = merge({
    remote-region = {
      route_table_key         = "production"
      destination_cidr_block  = var.peer_cidr_block
      next_hop_type           = "Attachment"
      next_hop_attachment_key = "remote-region"
      name                    = "to-remote-region"
    }
    }, local.vpn_enabled ? {
    for cidr in local.vpn_remote_cidrs : "vpn-${cidr}" => {
      route_table_key         = "production"
      destination_cidr_block  = cidr
      next_hop_type           = "Attachment"
      next_hop_attachment_key = "disaster-recovery"
      name                    = "to-vpn"
    }
  } : {})

  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
    Topology    = "multi-region"
  }
}

resource "terraform_data" "configuration" {
  input = {
    transit_router_id = var.peer_transit_router_id
    region_id         = var.peer_region_id
    cidr_block        = var.peer_cidr_block
  }

  lifecycle {
    precondition {
      condition     = var.region != var.peer_region_id
      error_message = "Local and peer regions must differ."
    }
    precondition {
      condition     = var.primary_vpc_id != var.branch_vpc_id
      error_message = "primary_vpc_id and branch_vpc_id must identify different VPCs."
    }
    precondition {
      condition = alltrue([
        for key, vpc in local.vpcs :
        data.volcenginecc_vpc_subnet.attachment[key].vpc_id == vpc.vpc_id &&
        startswith(data.volcenginecc_vpc_subnet.attachment[key].zone_id, "${var.region}-")
      ])
      error_message = "Each subnet must belong to its configured VPC and local region."
    }
    precondition {
      condition = local.vpn_enabled ? try(
        length(trimspace(var.vpn_zone_id)) > 0 && startswith(var.vpn_zone_id, "${var.region}-"),
        false
      ) : var.vpn_zone_id == null
      error_message = "vpn_connection_id and a local-region vpn_zone_id must be set together."
    }
    precondition {
      condition = (
        (var.bandwidth_package_id == null && var.peer_bandwidth == null) ||
        (try(length(trimspace(var.bandwidth_package_id)) > 0, false) && try(var.peer_bandwidth > 0 && floor(var.peer_bandwidth) == var.peer_bandwidth, false))
      )
      error_message = "bandwidth_package_id and peer_bandwidth must be set together or both omitted."
    }
  }
}
