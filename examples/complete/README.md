# Complete Cloud Connect Network Example

Describes multi-region VPC connectivity with a peer attachment, bandwidth package, forwarding and route-learning policies, Direct Connect gateway, and VPN connection.

## 1. Overview

This example owns the local Transit Router topology only. Both VPCs, attachment subnets, the Direct Connect gateway, VPN connection, and remote peer Transit Router are external dependencies.

## 2. Usage

Supply the IDs and zones for all existing network dependencies, then run:

```shell
terraform init
terraform plan
terraform apply
```

## 3. Examples

This is the complete example for a group network spanning regional VPCs, dedicated-line access, VPN disaster recovery, and a China-to-Asia peer connection.

## 4. Requirements

Terraform `>= 1.5.0` and `volcengine/volcenginecc >= 0.0.70` are required.

## 5. Providers

The caller configures `volcenginecc`.

## 6. Resources

The published cloud-connect-network module creates Transit Router resources.

## 7. Inputs

Inputs identify the existing VPCs, attachment subnets, Direct Connect gateway, VPN connection, remote peer Transit Router, reachable remote CIDR, and their zones.

## 8. Outputs

The example returns the Transit Router, attachment, route-table, forwarding-association, route-propagation, and bandwidth-package IDs.

## 9. Notes

The peer Transit Router must be in the configured remote region. Cross-account peers require authorization and acceptance before apply. The account also requires cross-border bandwidth approval to create the China-to-Asia package. Run a second `terraform plan` after apply; acceptance requires no changes.
