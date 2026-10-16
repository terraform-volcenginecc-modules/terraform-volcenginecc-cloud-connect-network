variable "region" {
  type        = string
  description = "Volcengine region configured by the caller."
}

variable "primary_vpc_id" {
  type        = string
  description = "Existing primary-region VPC ID."
}

variable "primary_attachment_subnet_id" {
  type        = string
  description = "Existing subnet ID for the primary VPC attachment."
}

variable "primary_attachment_zone_id" {
  type        = string
  description = "Availability zone containing primary_attachment_subnet_id."
}

variable "branch_vpc_id" {
  type        = string
  description = "Existing branch VPC ID."
}

variable "branch_attachment_subnet_id" {
  type        = string
  description = "Existing subnet ID for the branch VPC attachment."
}

variable "branch_attachment_zone_id" {
  type        = string
  description = "Availability zone containing branch_attachment_subnet_id."
}

variable "direct_connect_gateway_id" {
  type        = string
  description = "Existing Direct Connect Gateway ID."
}

variable "vpn_connection_id" {
  type        = string
  description = "Existing IPsec VPN connection ID."
}

variable "vpn_zone_id" {
  type        = string
  description = "Availability zone containing the VPN connection."
}

variable "peer_transit_router_id" {
  type        = string
  description = "Existing peer Transit Router ID in the remote region."
}

variable "peer_transit_router_region_id" {
  type        = string
  description = "Region ID of peer_transit_router_id, for example ap-southeast-1."
}

variable "peer_vpc_cidr_block" {
  type        = string
  description = "CIDR block reachable through the remote peer attachment."
}
