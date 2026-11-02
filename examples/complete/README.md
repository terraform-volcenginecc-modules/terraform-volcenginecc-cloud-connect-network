# Complete Cloud Connect Network Example

This example creates one local Transit Router (TR), attaches two existing VPCs, and connects to an existing same-account peer TR. VPN, Direct Connect, and inter-region bandwidth are optional.

## Ownership

The example manages:

- The local TR.
- Two local VPC attachments with automatic route publication.
- A production route table, associations, propagations, and static routes.
- A peer attachment to an existing remote TR.
- Optional VPN and Direct Connect Gateway attachments.

The caller owns all existing VPCs, subnets, the remote TR and its VPC/return routes, VPN connection, Direct Connect Gateway, and bandwidth package. This example does not modify remote-region resources or purchase bandwidth packages.

## Inputs

Required values use flat fields:

```hcl
region                     = "cn-beijing"
primary_vpc_id             = "vpc-primary"
primary_subnet_id          = "subnet-primary"
branch_vpc_id              = "vpc-branch"
branch_subnet_id           = "subnet-branch"
peer_transit_router_id     = "tr-remote"
peer_region_id             = "ap-southeast-1"
peer_cidr_block            = "10.21.0.0/16"
```

The example queries each subnet to obtain its zone and verify VPC ownership. The peer TR must already exist; its business VPC and return routes remain caller-managed.

VPN requires its connection ID and zone; Direct Connect requires one gateway ID:

```hcl
vpn_connection_id         = "vgc-existing"
vpn_zone_id               = "cn-beijing-a"
direct_connect_gateway_id = "dcg-existing"
```

VPN remote CIDRs are queried from the connection, while `vpn_zone_id` must be provided explicitly. Direct Connect uses route propagation by default.

Inter-region bandwidth uses two paired optional inputs:

```hcl
bandwidth_package_id = "tbp-existing"
peer_bandwidth       = 1
```

Set both or omit both. Omitting them creates a zero-bandwidth control-plane connection; cross-region traffic requires a positive bandwidth allocation. The package must cover both regions and have enough remaining capacity.

| Input | Required | Default | Description |
|---|---|---|---|
| `region` | yes | none | Local region. |
| `primary_vpc_id` | yes | none | Primary VPC ID. |
| `primary_subnet_id` | yes | none | Primary attachment subnet ID. |
| `branch_vpc_id` | yes | none | Branch VPC ID. |
| `branch_subnet_id` | yes | none | Branch attachment subnet ID. |
| `peer_transit_router_id` | yes | none | Existing peer TR ID. |
| `peer_region_id` | yes | none | Peer TR region. |
| `peer_cidr_block` | yes | none | Remote reachable CIDR. |
| `name` | no | `group-multi-region-ccn` | Local TR name. |
| `vpn_connection_id` | no | `null` | Existing VPN connection ID. |
| `vpn_zone_id` | no | `null` | VPN availability zone; set it with the VPN ID. |
| `direct_connect_gateway_id` | no | `null` | Existing Direct Connect Gateway ID. |
| `bandwidth_package_id` | no | `null` | Existing bandwidth package ID. |
| `peer_bandwidth` | no | `null` | Inter-region allocation in Mbps. |

The TR ASN is left unset so the cloud service applies its default.

## Execution

```shell
terraform init
terraform plan -parallelism=1 -var-file=<parameters> -out=deployment.tfplan
terraform apply -parallelism=1 deployment.tfplan
terraform plan -parallelism=1 -detailed-exitcode -var-file=<parameters>
terraform destroy -parallelism=1 -var-file=<parameters>
```

Use `-parallelism=1` to serialize operations on the same TR. Run a second Plan after apply to review configuration drift.

## Connectivity Requirements

End-to-end connectivity requires a business VPC attached to the remote TR, bidirectional routes, published VPC routes, and matching security group and network ACL rules. Cross-border connectivity also requires account qualification.

Destroy removes the peer allocation but leaves the caller-owned bandwidth package intact.
