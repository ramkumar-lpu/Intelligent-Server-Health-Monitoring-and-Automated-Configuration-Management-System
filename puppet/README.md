# Puppet Configuration Management (Phase 2 & Phase 4)

This directory stores Puppet Server 8.7.0 configuration, production manifests, and role modules applied to all 10 managed nodes (`node-01.infra.internal` through `node-10.infra.internal`).

## Structure

- `puppet.conf`: Puppet Server and manual CA configuration (`autosign = false`, `dns_alt_names = puppet,puppet.infra.internal`).
- `manifests/site.pp`: Role-based node classification across all 10 nodes.
- `modules/`:
  - `base_system/`: System baseline (`/etc/motd`, `/etc/devops_managed.json`, idempotent `apt_update`).
  - `nginx_web/`: Nginx installation and service management (`node-01`, `node-02`).
  - `postgres_db/`: PostgreSQL installation and internal service management (`node-03`, `node-04`).
  - `nodejs_app/`: Node.js runtime and internal health endpoint service (`node-05`, `node-06`).
  - `redis_cache/`: Redis server installation and service management (`node-07`, `node-08`).
  - `worker_node/`: Background worker runtime (`node-09`).
  - `backup_node/`: Backup tools (`rsync`, `cron`), staging directories, and scheduled check script (`node-10`).

## Certificate & Security Policy

- `autosign = false`: All node CSRs must be verified (`puppetserver ca list`) and signed manually (`puppetserver ca sign --certname ...`).
- Private keys and certificates remain in the `devops-puppet-server-ssl` volume and inside node containers, never committed to Git.
