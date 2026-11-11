# Jenkins Automation & CI/CD Pipelines (Scheduled for Phase 5)

This directory defines automation scripts and declarative pipeline definitions for the local Jenkins service running on Windows 11 (Port 8080).

## Planned Structure
- `Jenkinsfile`: Declarative pipeline executing validation, Terraform orchestration, and Puppet compliance triggers.
- `scripts/`:
  - `provision.ps1` / `provision.sh`: Invokes Terraform plan and apply.
  - `test_connectivity.ps1`: Verifies node health across the Docker bridge.
