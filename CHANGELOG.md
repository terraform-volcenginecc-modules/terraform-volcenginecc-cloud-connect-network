# Changelog

All notable changes to this module will be documented in this file.

## [Unreleased]

### Added

- Initial Transit Router based cloud-connect-network module.
- Stable-key VPC, Direct Connect Gateway, and VPN attachments.
- Custom route tables, static attachment and black-hole routes, and subscription bandwidth packages.
- Basic and complete examples for VPC connectivity and multi-region group networking.

### Deferred

- Cross-region peer attachment creation and bandwidth-package allocation, because Provider v0.0.70 has no resource that manages the association.
- Real-cloud create, update, no-change, replacement, destroy, and post-destroy read-back verification.
