output "transit_router_id" {
  description = "Transit Router ID."
  value       = module.cloud_connect_network.transit_router_id
}

output "attachment_ids" {
  description = "All network attachment IDs by attachment type."
  value = {
    vpc            = module.cloud_connect_network.vpc_attachment_ids
    direct_connect = module.cloud_connect_network.direct_connect_gateway_attachment_ids
    vpn            = module.cloud_connect_network.vpn_attachment_ids
    peer           = module.cloud_connect_network.peer_attachment_ids
  }
}

output "route_table_ids" {
  description = "Transit Router route table IDs."
  value       = module.cloud_connect_network.route_table_ids
}

output "bandwidth_package_ids" {
  description = "Cross-region bandwidth package IDs."
  value       = module.cloud_connect_network.bandwidth_package_ids
}

output "route_table_association_ids" {
  description = "Forwarding route-table association IDs."
  value       = module.cloud_connect_network.route_table_association_ids
}

output "route_table_propagation_ids" {
  description = "Route-learning propagation IDs."
  value       = module.cloud_connect_network.route_table_propagation_ids
}
