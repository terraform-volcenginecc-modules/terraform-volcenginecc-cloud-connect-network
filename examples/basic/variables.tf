variable "region" {
  type        = string
  description = "Volcengine region configured by the caller."
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC ID to attach. This example does not create the VPC."
}

variable "attachment_subnet_id" {
  type        = string
  description = "Existing subnet ID used as the VPC attachment point."
}

variable "attachment_zone_id" {
  type        = string
  description = "Availability zone containing attachment_subnet_id."
}
