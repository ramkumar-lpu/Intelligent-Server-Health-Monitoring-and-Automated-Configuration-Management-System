# Nagios Core Docker Build Directory

This directory contains the Dockerfile and configuration assets for the Nagios Core 4.5.2 monitoring server (`10.240.0.20`, Web UI on host port `8085`).

## Assets

- `Dockerfile`: Based on `jasonrivers/nagios:4.5.2`, copies Nagios and object configurations into `/opt/nagios/etc/`.
- `config/nagios.cfg`: Main Nagios configuration (`cfg_dir=/opt/nagios/etc/conf.d`).
- `config/cgi.cfg`: Web UI authorization configuration.
- `config/objects/commands.cfg`: Includes `check_nrpe`, `check_nrpe_timeout`, `check_nrpe_mem_cgroup`, and `check_nrpe_cpu_cgroup`.
- `config/objects/hosts/node-01.cfg` .. `node-10.cfg`: Host and 8-service definitions (`PING`, `SSH`, `Host Load - Shared Kernel`, `Memory Usage`, `Root Partition`, `Current Users`, `Total Processes`, `Container CPU - Cgroup`) for all 10 managed nodes.
