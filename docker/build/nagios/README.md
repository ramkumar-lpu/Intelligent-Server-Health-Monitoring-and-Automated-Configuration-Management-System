# Nagios Core Docker Build Directory (Scheduled for Phase 3)

This directory will contain the Dockerfile and configuration assets for the custom Nagios Core monitoring server.

## Planned Assets
- `Dockerfile`: Multi-stage compilation of Nagios Core 4.5 and `check_nrpe` plugin.
- `entrypoint.sh`: Bootstraps Nagios daemon and Apache/lighttpd web server on port 8085.
- `configs/`: Standardized templates for hosts, hostgroups, and service checks.
