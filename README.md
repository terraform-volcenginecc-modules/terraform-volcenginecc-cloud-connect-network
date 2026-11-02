# terraform-volcenginecc-cloud-connect-network

Terraform module for Volcengine Transit Router based cloud-connect networking across VPCs, Direct Connect gateways, and VPN connections.

## 1. Overview

The module creates one Transit Router as the cloud-connect core and optionally owns its VPC, Direct Connect Gateway, VPN, and cross-region peer attachments, custom route tables, route-table associations and propagations, and static routes. VPCs, subnets, Direct Connect gateways, VPN connections, peer Transit Routers, and bandwidth packages remain caller-owned.

Resource map keys are Terraform addresses. Renaming a key destroys and recreates its managed attachment, route table, or route entry.

## 2. Usage

### 2.1 Basic Usage

```hcl
module "cloud_connect_network" {
  source  = "terraform-volcenginecc-modules/cloud-connect-network/volcenginecc"
  version = "~> 1.0"

  name = "group-ccn"

  vpc_attachments = {
    application = {
      vpc_id = "vpc-xxxxxxxx"
      attach_points = [{
        subnet_id = "subnet-xxxxxxxx"
        zone_id   = "cn-beijing-a"
      }]
    }
  }
}
```

Provider credentials and region configuration belong to the caller. Do not place access keys in module configuration.

A cross-region connection must explicitly identify the existing peer TR and its region:

```hcl
peer_attachments = {
  remote = {
    peer_transit_router_id        = "tr-xxxxxxxx"
    peer_transit_router_region_id = "ap-southeast-1"
  }
}
```

## 3. Examples

- basic: attaches one existing VPC to a new Transit Router.
- complete: connects two local VPCs to an existing peer TR, with optional Direct Connect, VPN, and paired bandwidth-package allocation. The caller manages the remote business network. Peer connections are limited to the same account.

## 4. Requirements

| Name | Version |
|---|---|
| Terraform | `>= 1.5.0` |
| `volcengine/volcenginecc` | `>= 0.0.70` |

## 5. Providers

| Name | Source |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## 6. Resources

| Type | Name |
|---|---|
| Transit Router | `volcenginecc_transitrouter_transit_router.this` |
| VPC attachment | `volcenginecc_transitrouter_vpc_attachment.this` |
| Direct Connect attachment | `volcenginecc_transitrouter_direct_connect_gateway_attachment.this` |
| VPN attachment | `volcenginecc_transitrouter_vpn_attachment.this` |
| Peer attachment | `volcenginecc_transitrouter_peer_attachment.this` |
| Route table | `volcenginecc_transitrouter_transit_router_route_table.this` |
| Route-table association | `volcenginecc_transitrouter_transit_router_attachment_to_route_table.this` |
| Route-table propagation | `volcenginecc_transitrouter_route_table_propagation.this` |
| Route entry | `volcenginecc_transitrouter_transit_router_route_entry.this` |

## 7. Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | none | Transit Router name. |
| `description` | `string` | `null` | Transit Router description. |
| `project_name` | `string` | `null` | Project for the Transit Router. |
| `multicast_enabled` | `bool` | `null` | Enables Transit Router multicast. |
| `tags` | `map(string)` | `{}` | Common tags applied to all managed resources; resource-specific tags override duplicate keys. |
| `vpc_attachments` | `map(object)` | `{}` | Caller-owned VPC and subnet attachment definitions. |
| `direct_connect_gateway_attachments` | `map(object)` | `{}` | Caller-owned Direct Connect Gateway attachment definitions. |
| `vpn_attachments` | `map(object)` | `{}` | Caller-owned VPN connection attachment definitions. |
| `peer_attachments` | `map(object)` | `{}` | Cross-region peer attachments; each item requires a peer TR ID and region. |
| `route_tables` | `map(object)` | `{}` | Custom Transit Router route tables. |
| `route_table_associations` | `map(object)` | `{}` | Forwarding associations between managed route tables and attachments. |
| `route_table_propagations` | `map(object)` | `{}` | Route-learning propagations between managed route tables and attachments. |
| `route_entries` | `map(object)` | `{}` | Static route entries referencing a managed route table and attachment. |

## 8. Outputs

| Name | Description |
|---|---|
| `transit_router_id` | Transit Router ID. |
| `vpc_attachment_ids` | VPC attachment IDs by stable key. |
| `direct_connect_gateway_attachment_ids` | Direct Connect attachment IDs by stable key. |
| `vpn_attachment_ids` | VPN attachment IDs by stable key. |
| `peer_attachment_ids` | Cross-region peer attachment IDs by stable key. |
| `route_table_ids` | Custom route table IDs by stable key. |
| `route_table_association_ids` | Route-table association IDs by stable key. |
| `route_table_propagation_ids` | Route-table propagation IDs by stable key. |
| `route_entry_ids` | Static route entry IDs by stable key. |

## 9. Notes

- Resources are created through the Volcengine Transit Router resource family.
- A peer attachment requires a caller-owned peer Transit Router and the correct `peer_transit_router_region_id`. Cross-account peer attachments are not supported.
- The module never creates, updates, tags, or deletes bandwidth packages. To allocate peer bandwidth, set a caller-owned `bandwidth_package_id` together with a positive integer `bandwidth`; omit both for a zero-bandwidth control-plane connection.
- Before apply, verify that the external package is Available, covers both regions, and has enough remaining capacity. The complete example exposes only `bandwidth_package_id` and `peer_bandwidth` for this allocation.
- This is a breaking change for State that contains a module-created bandwidth package. If the package must remain, remove its old resource address from Terraform State before upgrading; otherwise Terraform will plan a delete that the prepaid-package API rejects.
- For VPC communication, configure both TR association/propagation and VPC return routes. `auto_publish_route_enabled = true` publishes TR routes to VPC route tables; default propagation learns subnets, not necessarily the entire VPC CIDR.
- Prefer independent `route_table_associations` for VPN. The legacy VPN `route_table_key` remains compatible, but must not be set together with an independent association for that attachment. Static VPN remote routes use `route_entries`; do not assume VPN supports generic propagation.
- Use `-parallelism=1` for apply and destroy to serialize operations on the same Transit Router.
- Route entries support only `Attachment` and `BlackHole` next-hop types. Attachment routes must refer to a managed VPC, Direct Connect Gateway, VPN, or peer attachment.
