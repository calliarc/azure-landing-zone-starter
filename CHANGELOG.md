# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-09-23

First working release.

### Added

- Management group and subscription layout sized for SMBs (root, platform, landing zones, sandbox, decommissioned)
- Hub-and-spoke networking with an NSG per subnet and optional Azure Firewall with forced egress routing
- Baseline Azure Policy assignments using built-in definitions: required tags (with inheritance), allowed regions, secure defaults and the Microsoft cloud security benchmark
- Centralized logging with Log Analytics (Activity Log export) and Defender for Cloud plans and security contact
- Monthly budget alerts (actual and forecast) and cost-allocation tags from day one
- Equivalent Terraform (azurerm 4.x) and Bicep versions

[Unreleased]: https://github.com/calliarc/azure-landing-zone-starter/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/calliarc/azure-landing-zone-starter/releases/tag/v0.1.0
