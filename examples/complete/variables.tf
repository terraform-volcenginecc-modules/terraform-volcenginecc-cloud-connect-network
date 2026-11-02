variable "name" {
  type        = string
  description = "Name of the local Transit Router."
  default     = "group-multi-region-ccn"

  validation {
    condition     = length(trimspace(var.name)) > 0 && length(var.name) <= 128
    error_message = "name must be non-empty and no longer than 128 characters."
  }
}

variable "region" {
  type        = string
  description = "Volcengine region configured by the caller."
}

variable "primary_vpc_id" {
  type        = string
  description = "Existing primary VPC ID."
}

variable "primary_subnet_id" {
  type        = string
  description = "Existing subnet ID used to attach the primary VPC."
}

variable "branch_vpc_id" {
  type        = string
  description = "Existing branch VPC ID."
}

variable "branch_subnet_id" {
  type        = string
  description = "Existing subnet ID used to attach the branch VPC."
}

variable "peer_transit_router_id" {
  type        = string
  description = "Existing same-account peer Transit Router ID."
}

variable "peer_region_id" {
  type        = string
  description = "Region ID of peer_transit_router_id."
}

variable "peer_cidr_block" {
  type        = string
  description = "Remote IPv4 CIDR reachable through the peer Transit Router."

  validation {
    condition     = can(cidrnetmask(var.peer_cidr_block))
    error_message = "peer_cidr_block must be a valid IPv4 CIDR."
  }
}

variable "direct_connect_gateway_id" {
  type        = string
  description = "Optional existing Direct Connect Gateway ID."
  default     = null
}

variable "vpn_connection_id" {
  type        = string
  description = "Optional existing IPsec VPN connection ID. Set it together with vpn_zone_id."
  default     = null
}

variable "vpn_zone_id" {
  type        = string
  description = "Optional availability zone of vpn_connection_id."
  default     = null
}

variable "bandwidth_package_id" {
  type        = string
  default     = null
  description = "Existing bandwidth package matching both peer regions. The example never creates or deletes it."

  validation {
    condition     = var.bandwidth_package_id == null ? true : length(trimspace(var.bandwidth_package_id)) > 0
    error_message = "bandwidth_package_id must be null or a non-empty existing package ID."
  }
}

variable "peer_bandwidth" {
  type        = number
  default     = null
  description = "Optional positive integer bandwidth allocation in Mbps. Set it together with bandwidth_package_id."

  validation {
    condition     = var.peer_bandwidth == null ? true : var.peer_bandwidth > 0 && floor(var.peer_bandwidth) == var.peer_bandwidth
    error_message = "peer_bandwidth must be null or a positive integer in Mbps."
  }
}
