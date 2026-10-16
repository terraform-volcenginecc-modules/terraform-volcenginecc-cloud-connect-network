output "transit_router_id" {
  description = "Transit Router ID."
  value       = module.cloud_connect_network.transit_router_id
}

output "vpc_attachment_ids" {
  description = "VPC attachment IDs."
  value       = module.cloud_connect_network.vpc_attachment_ids
}
