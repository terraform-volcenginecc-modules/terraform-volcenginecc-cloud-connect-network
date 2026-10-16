locals {
  resource_tags = length(var.tags) == 0 ? null : [
    for key in sort(keys(var.tags)) : {
      key   = key
      value = var.tags[key]
    }
  ]

  vpc_attachment_tags = {
    for key, attachment in var.vpc_attachments : key => length(merge(var.tags, attachment.tags)) == 0 ? null : [
      for tag_key in sort(keys(merge(var.tags, attachment.tags))) : {
        key   = tag_key
        value = merge(var.tags, attachment.tags)[tag_key]
      }
    ]
  }

  direct_connect_attachment_tags = {
    for key, attachment in var.direct_connect_gateway_attachments : key => length(merge(var.tags, attachment.tags)) == 0 ? null : [
      for tag_key in sort(keys(merge(var.tags, attachment.tags))) : {
        key   = tag_key
        value = merge(var.tags, attachment.tags)[tag_key]
      }
    ]
  }

  vpn_attachment_tags = {
    for key, attachment in var.vpn_attachments : key => length(merge(var.tags, attachment.tags)) == 0 ? null : [
      for tag_key in sort(keys(merge(var.tags, attachment.tags))) : {
        key   = tag_key
        value = merge(var.tags, attachment.tags)[tag_key]
      }
    ]
  }

  route_table_tags = {
    for key, route_table in var.route_tables : key => length(merge(var.tags, route_table.tags)) == 0 ? null : [
      for tag_key in sort(keys(merge(var.tags, route_table.tags))) : {
        key   = tag_key
        value = merge(var.tags, route_table.tags)[tag_key]
      }
    ]
  }

  bandwidth_package_tags = {
    for key, bandwidth_package in var.bandwidth_packages : key => length(merge(var.tags, bandwidth_package.tags)) == 0 ? null : [
      for tag_key in sort(keys(merge(var.tags, bandwidth_package.tags))) : {
        key   = tag_key
        value = merge(var.tags, bandwidth_package.tags)[tag_key]
      }
    ]
  }

  peer_attachment_tags = {
    for key, attachment in var.peer_attachments : key => length(merge(var.tags, attachment.tags)) == 0 ? null : [
      for tag_key in sort(keys(merge(var.tags, attachment.tags))) : {
        key   = tag_key
        value = merge(var.tags, attachment.tags)[tag_key]
      }
    ]
  }
}

resource "volcenginecc_transitrouter_transit_router" "this" {
  transit_router_name = var.name
  description         = var.description
  asn                 = var.asn
  project_name        = var.project_name
  multicast_enabled   = var.multicast_enabled
  tags                = local.resource_tags
}

resource "volcenginecc_transitrouter_vpc_attachment" "this" {
  for_each = var.vpc_attachments

  transit_router_id              = volcenginecc_transitrouter_transit_router.this.transit_router_id
  vpc_id                         = each.value.vpc_id
  transit_router_attachment_name = try(each.value.name, null)
  description                    = try(each.value.description, null)
  appliance_mode_enabled         = try(each.value.appliance_mode_enabled, null)
  auto_publish_route_enabled     = try(each.value.auto_publish_route_enabled, null)
  ipv_6_enabled                  = try(each.value.ipv6_enabled, null)
  tags                           = local.vpc_attachment_tags[each.key]
  attach_points                  = each.value.attach_points
}

resource "volcenginecc_transitrouter_direct_connect_gateway_attachment" "this" {
  for_each = var.direct_connect_gateway_attachments

  transit_router_id              = volcenginecc_transitrouter_transit_router.this.transit_router_id
  direct_connect_gateway_id      = each.value.direct_connect_gateway_id
  transit_router_attachment_name = try(each.value.name, null)
  description                    = try(each.value.description, null)
  tags                           = local.direct_connect_attachment_tags[each.key]
}

resource "volcenginecc_transitrouter_transit_router_route_table" "this" {
  for_each = var.route_tables

  transit_router_id               = volcenginecc_transitrouter_transit_router.this.transit_router_id
  transit_router_route_table_name = try(each.value.name, null)
  description                     = try(each.value.description, null)
  tags                            = local.route_table_tags[each.key]
}

resource "volcenginecc_transitrouter_vpn_attachment" "this" {
  for_each = var.vpn_attachments

  transit_router_id                 = volcenginecc_transitrouter_transit_router.this.transit_router_id
  vpn_connection_id                 = each.value.vpn_connection_id
  zone_id                           = each.value.zone_id
  transit_router_attachment_name    = try(each.value.name, null)
  description                       = try(each.value.description, null)
  transit_router_route_table_id     = try(volcenginecc_transitrouter_transit_router_route_table.this[each.value.route_table_key].transit_router_route_table_id, null)
  health_check_revoke_route_enabled = try(each.value.health_check_revoke_route_enabled, null)
  tags                              = local.vpn_attachment_tags[each.key]
}

locals {
  base_attachment_ids = merge(
    { for key, attachment in volcenginecc_transitrouter_vpc_attachment.this : key => attachment.transit_router_attachment_id },
    { for key, attachment in volcenginecc_transitrouter_direct_connect_gateway_attachment.this : key => attachment.transit_router_attachment_id },
    { for key, attachment in volcenginecc_transitrouter_vpn_attachment.this : key => attachment.transit_router_attachment_id },
  )
}

resource "volcenginecc_transitrouter_transit_router_route_entry" "this" {
  for_each = var.route_entries

  transit_router_route_table_id            = volcenginecc_transitrouter_transit_router_route_table.this[each.value.route_table_key].transit_router_route_table_id
  destination_cidr_block                   = each.value.destination_cidr_block
  transit_router_route_entry_next_hop_type = each.value.next_hop_type
  transit_router_route_entry_next_hop_id   = each.value.next_hop_type == "Attachment" ? local.attachment_ids[each.value.next_hop_attachment_key] : null
  transit_router_route_entry_name          = try(each.value.name, null)
  description                              = try(each.value.description, null)

  lifecycle {
    precondition {
      condition     = contains(keys(var.route_tables), each.value.route_table_key)
      error_message = "Every route entry must reference a key in route_tables."
    }

    precondition {
      condition     = each.value.next_hop_type == "BlackHole" ? try(each.value.next_hop_attachment_key, null) == null : contains(keys(local.attachment_ids), each.value.next_hop_attachment_key)
      error_message = "Attachment routes must reference a managed attachment key; BlackHole routes must omit next_hop_attachment_key."
    }
  }
}

resource "volcenginecc_transitrouter_transit_router_bandwidth_package" "this" {
  for_each = var.bandwidth_packages

  local_geographic_region_set_id        = each.value.local_geographic_region_set_id
  peer_geographic_region_set_id         = each.value.peer_geographic_region_set_id
  transit_router_bandwidth_package_name = try(each.value.name, null)
  description                           = try(each.value.description, null)
  bandwidth                             = try(each.value.bandwidth, null)
  billing_type                          = try(each.value.billing_type, null)
  period                                = try(each.value.period, null)
  period_unit                           = try(each.value.period_unit, null)
  renew_type                            = try(each.value.renew_type, null)
  renew_period                          = try(each.value.renew_period, null)
  remain_renew_times                    = try(each.value.remain_renew_times, null)
  line_operator                         = try(each.value.line_operator, null)
  project_name                          = var.project_name
  tags                                  = local.bandwidth_package_tags[each.key]

  lifecycle {
    precondition {
      condition     = (try(each.value.billing_type, null) == null || each.value.billing_type == 1) && (try(each.value.period_unit, null) == null || contains(["Month", "Year"], each.value.period_unit))
      error_message = "This module supports subscription bandwidth packages only: billing_type must be 1 and period_unit must be Month or Year."
    }
  }
}

resource "volcenginecc_transitrouter_peer_attachment" "this" {
  for_each = var.peer_attachments

  transit_router_id                   = volcenginecc_transitrouter_transit_router.this.transit_router_id
  peer_transit_router_id              = each.value.peer_transit_router_id
  peer_transit_router_region_id       = each.value.peer_transit_router_region_id
  transit_router_attachment_name      = try(each.value.name, null)
  description                         = try(each.value.description, null)
  transit_router_bandwidth_package_id = try(volcenginecc_transitrouter_transit_router_bandwidth_package.this[each.value.bandwidth_package_key].transit_router_bandwidth_package_id, null)
  bandwidth                           = try(each.value.bandwidth, null)
  tags                                = local.peer_attachment_tags[each.key]

  lifecycle {
    precondition {
      condition     = try(each.value.bandwidth_package_key, null) == null || try(contains(keys(var.bandwidth_packages), each.value.bandwidth_package_key), false)
      error_message = "peer attachments must reference a key in bandwidth_packages when bandwidth_package_key is set."
    }
  }
}

locals {
  attachment_ids = merge(
    local.base_attachment_ids,
    { for key, attachment in volcenginecc_transitrouter_peer_attachment.this : key => attachment.transit_router_attachment_id },
  )
}

resource "volcenginecc_transitrouter_transit_router_attachment_to_route_table" "this" {
  for_each = var.route_table_associations

  transit_router_route_table_id = volcenginecc_transitrouter_transit_router_route_table.this[each.value.route_table_key].transit_router_route_table_id
  transit_router_attachment_id  = local.attachment_ids[each.value.attachment_key]

  lifecycle {
    precondition {
      condition     = contains(keys(var.route_tables), each.value.route_table_key)
      error_message = "Every route-table association must reference a key in route_tables."
    }

    precondition {
      condition     = contains(keys(local.attachment_ids), each.value.attachment_key)
      error_message = "Every route-table association must reference a managed attachment key."
    }
  }
}

resource "volcenginecc_transitrouter_route_table_propagation" "this" {
  for_each = var.route_table_propagations

  transit_router_route_table_id = volcenginecc_transitrouter_transit_router_route_table.this[each.value.route_table_key].transit_router_route_table_id
  transit_router_attachment_id  = local.attachment_ids[each.value.attachment_key]

  lifecycle {
    precondition {
      condition     = contains(keys(var.route_tables), each.value.route_table_key)
      error_message = "Every route-table propagation must reference a key in route_tables."
    }

    precondition {
      condition     = contains(keys(local.attachment_ids), each.value.attachment_key)
      error_message = "Every route-table propagation must reference a managed attachment key."
    }
  }
}
