# terraform-volcenginecc-cloud-connect-network

Terraform module for Volcengine Transit Router based cloud-connect networking across VPCs, Direct Connect gateways, and VPN connections.

## 1. Overview

The module creates one Transit Router as the CCN core and optionally owns its VPC, Direct Connect Gateway, VPN, and cross-region peer attachments, custom route tables, route-table associations and propagations, static routes, and Transit Router bandwidth packages. VPCs, subnets, Direct Connect gateways, VPN connections, and peer Transit Routers remain caller-owned.

Resource map keys are Terraform addresses. Renaming a key destroys and recreates its managed attachment, route table, route entry, or bandwidth package.

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

## 3. Examples

- basic: attaches one existing VPC to a new Transit Router.
- complete: describes a multi-region VPC topology with Direct Connect, VPN, a peer attachment, forwarding and propagation policies, static routes, and a China-to-Asia bandwidth package.

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
| Bandwidth package | `volcenginecc_transitrouter_transit_router_bandwidth_package.this` |

## 7. Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | none | Transit Router name. |
| `description` | `string` | `null` | Transit Router description. |
| `asn` | `number` | `null` | Private BGP ASN. |
| `project_name` | `string` | `null` | Project for Transit Router and bandwidth packages. |
| `multicast_enabled` | `bool` | `null` | Enables Transit Router multicast. |
| `tags` | `map(string)` | `{}` | Common tags applied to all managed resources; resource-specific tags override duplicate keys. |
| `vpc_attachments` | `map(object)` | `{}` | Caller-owned VPC and subnet attachment definitions. |
| `direct_connect_gateway_attachments` | `map(object)` | `{}` | Caller-owned Direct Connect Gateway attachment definitions. |
| `vpn_attachments` | `map(object)` | `{}` | Caller-owned VPN connection attachment definitions. |
| `peer_attachments` | `map(object)` | `{}` | Cross-region peer attachment definitions. |
| `route_tables` | `map(object)` | `{}` | Custom Transit Router route tables. |
| `route_table_associations` | `map(object)` | `{}` | Forwarding associations between managed route tables and attachments. |
| `route_table_propagations` | `map(object)` | `{}` | Route-learning propagations between managed route tables and attachments. |
| `route_entries` | `map(object)` | `{}` | Static route entries referencing a managed route table and attachment. |
| `bandwidth_packages` | `map(object)` | `{}` | Subscription cross-region bandwidth packages. |

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
| `bandwidth_package_ids` | Bandwidth package IDs by stable key. |

## 9. Notes

- The Provider resource family is named `transitrouter`; this module uses it as the Volcengine CCN implementation rather than assuming an AWS Transit Gateway or Alibaba Cloud CEN schema.
- A peer attachment requires a caller-owned peer Transit Router and the correct `peer_transit_router_region_id`. Cross-account peers must be authorized and accepted before apply. When allocating bandwidth, configure both `bandwidth_package_key` and a positive `bandwidth`.
- Provider v0.0.70 exposes many optional attributes as `Optional+Computed`. The module passes `null` when an optional scalar is omitted and explicitly renders every supplied tag key/value. A real apply must be followed by a second `terraform plan`; release acceptance requires `No changes`.
- Route entries support only `Attachment` and `BlackHole` next-hop types. Attachment routes must refer to a managed VPC, Direct Connect Gateway, VPN, or peer attachment.
- Real-cloud validation details and any account-level limitations are recorded in [`examples/TEST_REPORT.zh-CN.md`](examples/TEST_REPORT.zh-CN.md).
