variable "name" {
  type        = string
  description = "Name of the Transit Router (CCN core)."

  validation {
    condition     = length(trimspace(var.name)) > 0 && length(var.name) <= 128
    error_message = "name must be a non-empty Transit Router name of at most 128 characters."
  }
}

variable "description" {
  type        = string
  description = "Optional Transit Router description."
  default     = null
}

variable "asn" {
  type        = number
  description = "Optional BGP ASN. Valid values are 64512-65534 and 4200000000-4294967294."
  default     = null

  validation {
    condition     = var.asn == null ? true : (var.asn >= 64512 && var.asn <= 65534) || (var.asn >= 4200000000 && var.asn <= 4294967294)
    error_message = "asn must be in a documented private ASN range."
  }
}

variable "project_name" {
  type        = string
  description = "Optional Volcengine project name for the Transit Router and bandwidth packages."
  default     = null
}

variable "multicast_enabled" {
  type        = bool
  description = "Whether multicast is enabled on the Transit Router."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources managed by this module. Per-resource tags override duplicate keys."
  default     = {}
}

variable "vpc_attachments" {
  type = map(object({
    vpc_id                     = string
    attach_points              = set(object({ subnet_id = string, zone_id = string }))
    name                       = optional(string)
    description                = optional(string)
    appliance_mode_enabled     = optional(bool)
    auto_publish_route_enabled = optional(bool)
    ipv6_enabled               = optional(bool)
    tags                       = optional(map(string), {})
  }))
  description = "VPC attachments keyed by a stable logical name. The module does not own the VPCs or subnets."
  default     = {}
}

variable "direct_connect_gateway_attachments" {
  type = map(object({
    direct_connect_gateway_id = string
    name                      = optional(string)
    description               = optional(string)
    tags                      = optional(map(string), {})
  }))
  description = "Direct Connect Gateway attachments keyed by a stable logical name. The module does not own the gateways."
  default     = {}
}

variable "vpn_attachments" {
  type = map(object({
    vpn_connection_id                 = string
    zone_id                           = string
    name                              = optional(string)
    description                       = optional(string)
    route_table_key                   = optional(string)
    health_check_revoke_route_enabled = optional(bool)
    tags                              = optional(map(string), {})
  }))
  description = "VPN connection attachments keyed by a stable logical name. The module does not own VPN connections."
  default     = {}
}

variable "route_tables" {
  type = map(object({
    name        = optional(string)
    description = optional(string)
    tags        = optional(map(string), {})
  }))
  description = "Custom Transit Router route tables keyed by a stable logical name."
  default     = {}
}

variable "peer_attachments" {
  type = map(object({
    peer_transit_router_id        = string
    peer_transit_router_region_id = string
    bandwidth_package_key         = optional(string)
    bandwidth                     = optional(number)
    name                          = optional(string)
    description                   = optional(string)
    tags                          = optional(map(string), {})
  }))
  description = "Cross-region peer attachments keyed by a stable logical name. The peer Transit Router is external, potentially in another account, and must be authorized before apply."
  default     = {}

  validation {
    condition = alltrue([
      for attachment in values(var.peer_attachments) :
      (try(attachment.bandwidth_package_key, null) == null && try(attachment.bandwidth, null) == null) ||
      (try(attachment.bandwidth_package_key, null) != null && try(attachment.bandwidth > 0, false))
    ])
    error_message = "peer_attachments must set bandwidth_package_key and a positive bandwidth together, or omit both."
  }
}

variable "route_table_associations" {
  type = map(object({
    route_table_key = string
    attachment_key  = string
  }))
  description = "Forwarding route-table associations keyed by a stable logical name. attachment_key references a VPC, Direct Connect Gateway, VPN, or peer attachment."
  default     = {}
}

variable "route_table_propagations" {
  type = map(object({
    route_table_key = string
    attachment_key  = string
  }))
  description = "Route-learning propagations keyed by a stable logical name. attachment_key references a VPC, Direct Connect Gateway, VPN, or peer attachment."
  default     = {}
}

variable "route_entries" {
  type = map(object({
    route_table_key         = string
    destination_cidr_block  = string
    next_hop_type           = string
    next_hop_attachment_key = optional(string)
    name                    = optional(string)
    description             = optional(string)
  }))
  description = "Static route entries keyed by a stable logical name. Attachment next hops reference a VPC, Direct Connect, or VPN attachment key."
  default     = {}

  validation {
    condition     = alltrue([for route in values(var.route_entries) : contains(["Attachment", "BlackHole"], route.next_hop_type)])
    error_message = "route_entries[*].next_hop_type must be Attachment or BlackHole."
  }
}

variable "bandwidth_packages" {
  type = map(object({
    local_geographic_region_set_id = string
    peer_geographic_region_set_id  = string
    name                           = optional(string)
    description                    = optional(string)
    bandwidth                      = optional(number)
    billing_type                   = optional(number)
    period                         = optional(number)
    period_unit                    = optional(string)
    renew_type                     = optional(string)
    renew_period                   = optional(number)
    remain_renew_times             = optional(number)
    line_operator                  = optional(string)
    tags                           = optional(map(string), {})
  }))
  description = "Cross-region bandwidth packages keyed by a stable logical name. Reference a package from peer_attachments to allocate bandwidth to a managed peer attachment."
  default     = {}
}
