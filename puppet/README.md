# Puppet Configuration Management (Scheduled for Phase 2)

This directory will store Puppet configuration, environments, and reusable manifests applied to the 10 managed nodes.

## Planned Structure
- `puppet.conf`: Puppet Master and CA server configurations.
- `autosign.conf`: Secure autosign rules for `*.infra.internal`.
- `manifests/site.pp`: Main manifest entry point and node classification.
- `modules/`:
  - `base_system/`: System baseline, unprivileged users, and standard dependencies.
  - `nrpe_client/`: Enforces NRPE configuration, custom check scripts, and firewall allowances.
