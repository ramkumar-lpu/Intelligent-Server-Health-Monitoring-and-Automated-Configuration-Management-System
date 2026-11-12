# Jenkins Automation & CI/CD Pipeline

This directory contains the declarative pipeline definition for the local **Jenkins Windows Service** (port `8080`, running natively on Windows 11 outside Docker).

## Files

- `Jenkinsfile`: Declarative pipeline covering:
  1. Source checkout (`checkout scm`)
  2. Terraform formatting and validation (`terraform fmt -check -recursive`, `terraform init -backend=false -input=false`, `terraform validate`) via `hashicorp/terraform:latest`
  3. Puppet manifest syntax validation (`puppet parser validate` inside `puppet-server`)
  4. Shell script syntax checks (`sh -n` via `ubuntu:24.04`) and Docker Compose config validation
  5. Nagios Core pre-flight validation (`/opt/nagios/bin/nagios -v /opt/nagios/etc/nagios.cfg`)
  6. Automated verification scripts (`scripts/verify-phase1.ps1`, `verify-phase2.ps1`, `verify-phase3.ps1`, and `verify-phase4.ps1`)
  7. Manual approval gate (`input`) before controlled `terraform plan -input=false`

## Windows Service Setup Notes

1. Keep Jenkins running as a Windows Service (`http://localhost:8080`, running as `LocalSystem`); do not containerize it or modify existing jobs (`portfolio`, `Self-Healing-Pipeline`).
2. Sign in to `http://localhost:8080` and create a new **Pipeline** job (e.g., `Devops-Project-CI`) without modifying existing jobs.
3. Under **Pipeline**, choose **Pipeline script from SCM**, select **Git**, set Repository URL to `D:\Devops_Project` (or the GitHub remote with existing Jenkins credentials), branch `*/main`, and Script Path `jenkins/Jenkinsfile`.
4. Trigger **Build with Parameters** (`RUN_INTEGRATION_CHECKS=true`, `ENABLE_DEPLOY_GATE=false` for validation-only runs, or `true` to test the manual approval `input` gate).
5. Never store credentials, `.env` values, or Puppet private keys inside `Jenkinsfile`; use Jenkins Credentials Manager if external SCM credentials are required.
