output "transit_router_id" {
  description = "ID of the Transit Router that provides the CCN core."
  value       = volcenginecc_transitrouter_transit_router.this.transit_router_id
}

output "vpc_attachment_ids" {
  description = "VPC attachment IDs keyed by the input's stable logical keys."
  value       = { for key, attachment in volcenginecc_transitrouter_vpc_attachment.this : key => attachment.transit_router_attachment_id }
}

output "direct_connect_gateway_attachment_ids" {
  description = "Direct Connect Gateway attachment IDs keyed by the input's stable logical keys."
  value       = { for key, attachment in volcenginecc_transitrouter_direct_connect_gateway_attachment.this : key => attachment.transit_router_attachment_id }
}

output "vpn_attachment_ids" {
  description = "VPN attachment IDs keyed by the input's stable logical keys."
  value       = { for key, attachment in volcenginecc_transitrouter_vpn_attachment.this : key => attachment.transit_router_attachment_id }
}

output "peer_attachment_ids" {
  description = "Cross-region peer attachment IDs keyed by the input's stable logical keys."
  value       = { for key, attachment in volcenginecc_transitrouter_peer_attachment.this : key => attachment.transit_router_attachment_id }
}

output "route_table_ids" {
  description = "Custom Transit Router route table IDs keyed by the input's stable logical keys."
  value       = { for key, route_table in volcenginecc_transitrouter_transit_router_route_table.this : key => route_table.transit_router_route_table_id }
}

output "route_table_association_ids" {
  description = "Forwarding route-table association IDs keyed by the input's stable logical keys."
  value       = { for key, association in volcenginecc_transitrouter_transit_router_attachment_to_route_table.this : key => association.id }
}

output "route_table_propagation_ids" {
  description = "Route-learning propagation IDs keyed by the input's stable logical keys."
  value       = { for key, propagation in volcenginecc_transitrouter_route_table_propagation.this : key => propagation.id }
}

output "route_entry_ids" {
  description = "Static Transit Router route entry IDs keyed by the input's stable logical keys."
  value       = { for key, route_entry in volcenginecc_transitrouter_transit_router_route_entry.this : key => route_entry.transit_router_route_entry_id }
}

output "bandwidth_package_ids" {
  description = "Transit Router bandwidth package IDs keyed by the input's stable logical keys."
  value       = { for key, bandwidth_package in volcenginecc_transitrouter_transit_router_bandwidth_package.this : key => bandwidth_package.transit_router_bandwidth_package_id }
}
