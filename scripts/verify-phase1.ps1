<#
.SYNOPSIS
    Automated Phase 1 Verification Script for "node-01" Managed Node.
.DESCRIPTION
    Validates Docker image availability, container health, Ubuntu 24.04 OS,
    Puppet Agent 8, NRPE daemon, SSH hardening, and process supervisor.
    Stops immediately with an actionable error message upon encountering any failure.
.NOTES
    Compatible with Windows PowerShell 5.1 and PowerShell Core 7+.
#>

[CmdletBinding()]
param(
    [string]$ContainerName = "node-01",
    [string]$ImageName = "custom-ubuntu24-managed-node:latest"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Title)
    Write-Host "`n[PHASE 1 TEST] $Title" -ForegroundColor Cyan
}

function Write-Pass {
    param([string]$Message)
    Write-Host "  [PASS] $Message" -ForegroundColor Green
}

function Stop-OnFail {
    param(
        [string]$Message,
        [string]$TroubleshootingNote = ""
    )
    Write-Host "  [FAIL] $Message" -ForegroundColor Red
    if ($TroubleshootingNote) {
        Write-Host "`n[TROUBLESHOOTING TIP] $TroubleshootingNote" -ForegroundColor Yellow
    }
    Write-Host "`nVerification terminated prematurely due to failure." -ForegroundColor Red
    exit 1
}

# --- Test 1: Image Availability & Footprint ---
Write-Step "Checking Docker image '$ImageName' availability..."
$ImageInspect = docker image inspect $ImageName 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($ImageInspect)) {
    Stop-OnFail "Docker image '$ImageName' was not found locally." "Build the image first using 'docker compose build' from the 'docker/compose' directory."
}
$ImageSize = (docker images $ImageName --format "{{.Size}}")
Write-Pass "Image '$ImageName' is present locally (Size: $ImageSize)."

# --- Test 2: Container Running State ---
Write-Step "Checking container '$ContainerName' status..."
$ContainerState = (docker inspect --format '{{.State.Status}}' $ContainerName 2>$null)
if ($ContainerState -ne "running") {
    Stop-OnFail "Container '$ContainerName' is not running (Current state: '$ContainerState')." "Start the container using 'docker compose up -d' in the 'docker/compose' directory."
}
Write-Pass "Container '$ContainerName' is in running state."

# --- Test 3: Docker Health Check ---
Write-Step "Inspecting container health status..."
$MaxWaitSeconds = 30
$IntervalSeconds = 5
$ElapsedTime = 0
$HealthStatus = ""

while ($ElapsedTime -lt $MaxWaitSeconds) {
    $HealthStatus = (docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' $ContainerName 2>$null)
    if ($HealthStatus -eq "healthy") {
        break
    }
    Write-Host "  [WAIT] Health status is '$HealthStatus'. Waiting ${IntervalSeconds}s (Elapsed: ${ElapsedTime}s)..." -ForegroundColor Yellow
    Start-Sleep -Seconds $IntervalSeconds
    $ElapsedTime += $IntervalSeconds
}

if ($HealthStatus -ne "healthy") {
    Stop-OnFail "Container health check reported '$HealthStatus' (expected 'healthy')." "Check container logs using 'docker compose logs node-01' or inspect supervisor logs."
}
Write-Pass "Container health check confirmed: healthy."

# --- Test 4: Ubuntu 24.04 OS Release ---
Write-Step "Verifying operating system version..."
$OsText = (docker exec $ContainerName cat /etc/os-release 2>$null | Out-String)
if ($OsText -notmatch 'VERSION_ID="24.04"') {
    Stop-OnFail "Container is not running Ubuntu 24.04 LTS." "Check the base image declaration in 'docker/build/managed-node/Dockerfile'."
}
Write-Pass "Operating System confirmed: Ubuntu 24.04 LTS (Noble Numbat)."

# --- Test 5: Puppet Agent 8 Installation ---
Write-Step "Verifying Puppet Agent installation and version..."
$PuppetVerText = (docker exec $ContainerName /opt/puppetlabs/bin/puppet --version 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $PuppetVerText -notmatch "^8\.") {
    Stop-OnFail "Puppet Agent 8 verification failed (Output: '$PuppetVerText')." "Ensure Puppet 8 release package and puppet-agent installed cleanly during image build."
}
Write-Pass "Puppet Agent 8 verified: Version $PuppetVerText."

# --- Test 6: Supervisor & Critical Services Status ---
Write-Step "Verifying Supervisor process table..."
$SupervisorText = (docker exec $ContainerName supervisorctl status 2>$null | Out-String)
Write-Host $SupervisorText.Trim()

if ($SupervisorText -notmatch "sshd\s+RUNNING") {
    Stop-OnFail "Service 'sshd' is not RUNNING under supervisor." "Inspect '/var/log/supervisor/sshd_err.log' inside the container."
}
Write-Pass "Service 'sshd' is RUNNING."

if ($SupervisorText -notmatch "nrpe\s+RUNNING") {
    Stop-OnFail "Service 'nrpe' is not RUNNING under supervisor." "Inspect '/var/log/supervisor/nrpe_err.log' inside the container."
}
Write-Pass "Service 'nrpe' is RUNNING."

if ($SupervisorText -match "puppet-agent\s+STOPPED") {
    Write-Pass "Service 'puppet-agent' is safely STOPPED (deferred to Phase 2)."
} else {
    Write-Host "  [INFO] Puppet Agent status is: $SupervisorText" -ForegroundColor Yellow
}

# --- Test 7: NRPE Plugin Local Execution ---
Write-Step "Verifying local NRPE check plugin execution..."
$LoadText = (docker exec $ContainerName /usr/lib/nagios/plugins/check_load -r -w .15,.10,.05 -c .30,.25,.20 2>$null | Out-String).Trim()
if ($LoadText -notmatch "OK|WARNING|CRITICAL") {
    Stop-OnFail "Nagios check_load failed to execute (Output: '$LoadText')." "Verify '/usr/lib/nagios/plugins/check_load' exists and is executable."
}
Write-Pass "Nagios check_load plugin executed: $LoadText"

$MemText = (docker exec $ContainerName /usr/lib/nagios/plugins/check_mem -w 80 -c 90 2>$null | Out-String).Trim()
if ($MemText -notmatch "Memory:") {
    Stop-OnFail "Custom check_mem failed to execute (Output: '$MemText')." "Verify '/usr/lib/nagios/plugins/check_mem' script syntax and permissions."
}
Write-Pass "Custom check_mem plugin executed: $MemText"

# --- Test 8: SSH Configuration Hardening ---
Write-Step "Validating SSH hardening configuration..."
$SshText = (docker exec $ContainerName cat /etc/ssh/sshd_config 2>$null | Out-String)
if ($SshText -notmatch "PermitRootLogin no" -or $SshText -notmatch "PasswordAuthentication no") {
    Stop-OnFail "SSH configuration does not meet security hardening requirements." "Check '/etc/ssh/sshd_config' for PermitRootLogin no and PasswordAuthentication no."
}
Write-Pass "SSH hardening confirmed: Root login and password authentication are disabled."

# --- Final Success Summary ---
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "PHASE 1 VERIFICATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "All tests passed without error." -ForegroundColor Green
Write-Host "========================================================`n" -ForegroundColor Cyan
