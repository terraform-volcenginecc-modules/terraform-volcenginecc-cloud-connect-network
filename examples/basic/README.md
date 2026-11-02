# Basic Cloud Connect Network Example

Creates a Transit Router and attaches one existing VPC through one existing subnet attachment point.

## 1. Overview

This example owns only the Transit Router and its VPC attachment. The VPC and subnet must already exist.

## 2. Usage

Provide `region`, `vpc_id`, `attachment_subnet_id`, and `attachment_zone_id`, then run:

```shell
terraform init
terraform plan
terraform apply
```

## 3. Examples

This is the basic example.

## 4. Requirements

Terraform `>= 1.5.0` and `volcengine/volcenginecc >= 0.0.70` are required.

## 5. Providers

The caller configures `volcenginecc`.

## 6. Resources

The example references the repository root module through `source = "../.."`.

## 7. Inputs

The four required inputs identify the target region, VPC, subnet, and availability zone.

## 8. Outputs

The example returns the Transit Router and VPC attachment IDs.

## 9. Notes

Use `-parallelism=1` to serialize Transit Router operations. Run `terraform plan` after apply to review configuration drift. This example creates one VPC attachment and does not configure cross-network communication. Destroy only after confirming that the attachment is no longer needed.
