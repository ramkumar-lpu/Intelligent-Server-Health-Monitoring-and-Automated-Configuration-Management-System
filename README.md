# Intelligent Server Health Monitoring & Automated Configuration Management System

A multi-tier DevOps infrastructure providing declarative infrastructure provisioning, continuous configuration enforcement, and centralized telemetry across managed Linux nodes.

---

## Environment Prerequisites

* **Operating System:** Windows 11 (22H2 or higher)
* **Container Runtime:** Docker Desktop with WSL2 backend enabled
* **Hardware Footprint:** Tuned for a 16 GB RAM workstation
* **Host Services:** Local Windows Jenkins service running on port `8080` (untouched in Phase 1)
* **Shell:** Windows PowerShell 5.1+ or PowerShell Core 7+

---

## Phase 1 Scope & Architecture

Phase 1 establishes the repository architecture and packages the **unified Linux managed node base image** (`custom-ubuntu24-managed-node:latest`). Only a single test node (`node-01`) is provisioned in this phase for isolated validation.

### Component Details
* **Base OS:** Ubuntu 24.04 LTS (Noble Numbat)
* **Configuration Management:** Puppet Agent 8 (Installed from official Puppet repository `apt.puppet.com/puppet8-release-noble.deb`; agent catalog run disabled until Phase 2)
* **Monitoring:** Nagios Remote Plugin Executor (NRPE) daemon + Monitoring Plugins
* **Secure Access:** OpenSSH Server with password authentication and root login disabled
* **Process Supervisor:** `supervisor` acting as PID 1 to reliably manage daemons and signal forwarding

---

## Phase 1 Verified Configuration & Baseline Audit

Phase 1 has been completed and verified. The baseline configuration is preserved and `node-01` remains active as our first managed target.

| Parameter | Recorded Value / State |
| :--- | :--- |
| **Image Name** | `custom-ubuntu24-managed-node:latest` |
| **Image ID** | `sha256:989caccc3dbb333b24e00f3be49475e49d94ae3cde877e34a3967d5cd4ad55d1` |
| **Image Disk Size** | `406 MB` |
| **Container Name** | `node-01` |
| **Container Hostname**| `node-01.infra.internal` |
| **Container Status** | `Up (healthy)` |
| **Docker Network** | `devops-infra-net` (`10.240.0.0/16`, Gateway: `10.240.0.1`) |
| **Static IPv4** | `10.240.0.101` |
| **Base OS Version** | `Ubuntu 24.04.5 LTS (Noble Numbat)` |
| **Puppet Agent Version** | `8.10.0` (in `/opt/puppetlabs/bin/puppet`) |
| **Process Table** | Supervisor PID 1; `sshd` RUNNING; `nrpe` RUNNING; `puppet-agent` STOPPED |
| **Memory Footprint**| `22.62 MiB` / `512 MiB` (`4.42%` utilization) |
| **CPU Footprint** | `0.01%` |
| **Verification Suite**| Passed all 8 tests in `scripts/verify-phase1.ps1` |

---

## Repository Structure

```
Devops_Project/
├── .dockerignore
├── .gitignore
├── README.md
├── docker/
│   ├── build/
│   │   ├── managed-node/
│   │   │   ├── Dockerfile
│   │   │   ├── entrypoint.sh
│   │   │   ├── configs/
│   │   │   │   ├── nrpe.cfg
│   │   │   │   ├── puppet.conf
│   │   │   │   ├── sshd_config
│   │   │   │   └── supervisord.conf
│   │   │   └── scripts/
│   │   │       └── check_mem
│   │   └── nagios/                     # Placeholder for Phase 3
│   │       └── README.md
│   ├── compose/
│   │   ├── .env.example
│   │   └── docker-compose.yml          # Phase 1: Launches only node-01
│   └── volumes/
│       └── .gitkeep
├── terraform/                          # Placeholder for Phase 4
│   └── README.md
├── puppet/                             # Placeholder for Phase 2
│   └── README.md
├── jenkins/                            # Placeholder for Phase 5
│   └── README.md
├── scripts/
│   └── verify-phase1.ps1               # Automated test suite
└── extensions/
    └── k3s/                            # Placeholder for Phase 7
        └── README.md
```

---

## Phase 1 Execution & Validation (PowerShell)

### 1. Build the Managed Node Image
From the repository root (`D:\Devops_Project`):
```powershell
Set-Location -Path "docker\compose"
docker compose build
```

### 2. Start the Test Node (`node-01`)
```powershell
docker compose up -d
```

### 3. Check Container Status
```powershell
docker compose ps
```

### 4. Verify Ubuntu Version
```powershell
docker exec node-01 cat /etc/os-release
```

### 5. Verify Puppet Agent 8 Installation
```powershell
docker exec node-01 /opt/puppetlabs/bin/puppet --version
```

### 6. Verify NRPE Installation and Service Status
```powershell
docker exec node-01 supervisorctl status nrpe
docker exec node-01 /usr/lib/nagios/plugins/check_load -r -w .15,.10,.05 -c .30,.25,.20
```

### 7. Verify OpenSSH Daemon Status
```powershell
docker exec node-01 supervisorctl status sshd
```

### 8. Inspect Image Footprint
```powershell
docker images custom-ubuntu24-managed-node:latest
```

### 9. Check Container Logs
```powershell
docker compose logs node-01
```

### 10. Run Automated Verification Test Suite
From the repository root:
```powershell
Set-Location -Path "..\..\"
.\scripts\verify-phase1.ps1
```

### 11. Stop and Clean Test Container
```powershell
Set-Location -Path "docker\compose"
docker compose down
```

---

## Expected Results

| Verification Check | Expected Output |
| :--- | :--- |
| **Container State** | `running` and Health status `healthy` |
| **Ubuntu Version** | `VERSION="24.04 LTS (Noble Numbat)"` |
| **Puppet Agent Version** | `8.x.x` (e.g. `8.4.0`+) |
| **NRPE Status** | `nrpe RUNNING pid <PID>, uptime <TIME>` |
| **SSH Daemon Status** | `sshd RUNNING pid <PID>, uptime <TIME>` |
| **Puppet Agent Status** | `puppet-agent STOPPED` (Controlled Phase 1 safety state) |
| **Nagios check_load** | `OK - load average: ...` |
| **Custom check_mem** | `OK - Memory: XX% used (...)` |
| **Image Size** | Minimal single footprint (~280 MB - 360 MB) |

---

## Windows Docker Desktop Troubleshooting

1. **Docker Engine Not Responding / WSL2 Backend Issue:**
   * Ensure Docker Desktop is running and the whale icon is solid in the system tray.
   * If `docker compose` fails with a named pipe error:
     ```powershell
     wsl --status
     wsl --shutdown
     ```
     Restart Docker Desktop from the Start Menu.

2. **Windows Line Endings (CRLF vs LF) on Shell Scripts:**
   * If `entrypoint.sh` or `check_mem` fails with `^M: bad interpreter`:
     Ensure your git configuration preserves Linux line endings:
     ```powershell
     git config core.autocrlf input
     ```
     Or convert the files using PowerShell:
     ```powershell
     (Get-Content -Raw docker\build\managed-node\entrypoint.sh) -replace "`r`n", "`n" | Set-Content -NoNewline docker\build\managed-node\entrypoint.sh
     (Get-Content -Raw docker\build\managed-node\scripts\check_mem) -replace "`r`n", "`n" | Set-Content -NoNewline docker\build\managed-node\scripts\check_mem
     ```

3. **Port Conflicts with Existing Host Services:**
   * The managed node does **not** bind port `22` or `5666` to `0.0.0.0` on the Windows host.
   * Your existing Jenkins Windows Service on `8080` remains completely undisturbed.

4. **Resource Constraints on 16 GB RAM Machines:**
   * Docker Desktop `settings.json` or `.wslconfig` (located in `%USERPROFILE%\.wslconfig`) should limit WSL2 memory:
     ```ini
     [wsl2]
     memory=6GB
     processors=4
     ```
   * The `docker-compose.yml` applies resource limits (`limits.memory: 512M`) per managed node.
