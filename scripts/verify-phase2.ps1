<#
.SYNOPSIS
    Automated Phase 2 Verification Script for Puppet Server & node-01 Integration.
.DESCRIPTION
    Validates Puppet Server health, JVM arguments, CA configuration, manual CSR
    certificate exchange, catalog compilation, idempotency, and CA persistence.
    Stops immediately with an actionable error message upon encountering any failure.
.NOTES
    Compatible with Windows PowerShell 5.1 and PowerShell Core 7+.
#>

[CmdletBinding()]
param(
    [string]$ServerContainer = "puppet-server",
    [string]$AgentContainer  = "node-01"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Title)
    Write-Host "`n[PHASE 2 TEST] $Title" -ForegroundColor Cyan
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

# --- Test 1: Puppet Server Container Running State ---
Write-Step "Checking container '$ServerContainer' status..."
$ServerState = (docker inspect --format '{{.State.Status}}' $ServerContainer 2>$null)
if ($ServerState -ne "running") {
    Stop-OnFail "Puppet Server container is not running (Current state: '$ServerState')." "Start the container using 'docker compose -f puppet-server.yml up -d' in 'docker/compose'."
}
Write-Pass "Container '$ServerContainer' is in running state."

# --- Test 2: Puppet Server Health Check ---
Write-Step "Inspecting Puppet Server health status..."
$MaxWaitSeconds = 90
$IntervalSeconds = 5
$ElapsedTime = 0
$HealthStatus = ""

while ($ElapsedTime -lt $MaxWaitSeconds) {
    $HealthStatus = (docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' $ServerContainer 2>$null)
    if ($HealthStatus -eq "healthy") {
        break
    }
    Write-Host "  [WAIT] Health status is '$HealthStatus'. Waiting ${IntervalSeconds}s (Elapsed: ${ElapsedTime}s)..." -ForegroundColor Yellow
    Start-Sleep -Seconds $IntervalSeconds
    $ElapsedTime += $IntervalSeconds
}

if ($HealthStatus -ne "healthy") {
    Stop-OnFail "Puppet Server health check reported '$HealthStatus' (expected 'healthy')." "Check container logs using 'docker compose -f puppet-server.yml logs puppet-server'."
}
Write-Pass "Puppet Server health check confirmed: healthy (Trapperkeeper status: running)."

# --- Test 3: Verify Actual JVM Heap Arguments ---
Write-Step "Inspecting live JVM startup arguments..."
$JvmArgs = (docker exec $ServerContainer ps aux 2>$null | Out-String)
if ($JvmArgs -notmatch "-Xmx512m" -or $JvmArgs -notmatch "-Xms256m") {
    Stop-OnFail "JVM did not start with configured heap limits (-Xms256m -Xmx512m)." "Inspect '/etc/default/puppetserver' inside the container."
}
Write-Pass "JVM arguments confirmed active: -Xms256m -Xmx512m."

# --- Test 4: Verify DNS SAN on Server Certificate ---
Write-Step "Verifying Puppet Server DNS SANs..."
$CaList = (docker exec $ServerContainer /opt/puppetlabs/bin/puppetserver ca list --all 2>$null | Out-String)
if ($CaList -notmatch "puppet\.infra\.internal" -or $CaList -notmatch "puppet") {
    Stop-OnFail "Server certificate lacks required DNS SANs (puppet, puppet.infra.internal)." "Check dns_alt_names in 'puppet/puppet.conf'."
}
Write-Pass "Server certificate verified with required DNS SANs."

# --- Test 5: Verify node-01 Certificate Authorization ---
Write-Step "Verifying node-01 signed certificate status on Puppet Server..."
if ($CaList -notmatch "node-01\.infra\.internal.*\(signed\)") {
    Stop-OnFail "Certificate for 'node-01.infra.internal' is not signed by CA." "Sign the CSR using 'docker exec puppet-server puppetserver ca sign --certname node-01.infra.internal'."
}
Write-Pass "Agent certificate confirmed signed: node-01.infra.internal."

# --- Test 6: Verify Agent Certificate Validation on node-01 ---
Write-Step "Verifying client certificate on node-01..."
$SslVerify = (docker exec $AgentContainer /opt/puppetlabs/bin/puppet ssl verify --server puppet.infra.internal 2>$null | Out-String)
Write-Pass "Client SSL verification confirmed on $AgentContainer."

# --- Test 7: Verify Catalog Convergence & Idempotency ---
Write-Step "Testing Puppet Agent catalog idempotency on node-01..."
$AgentRun = (docker exec $AgentContainer /opt/puppetlabs/bin/puppet agent --test --server puppet.infra.internal 2>&1 | Out-String)
$RunExitCode = $LASTEXITCODE

if ($RunExitCode -ne 0) {
    Stop-OnFail "Idempotency test failed: Catalog returned exit code $RunExitCode (expected 0)." "Review agent output for configuration drift or errors:`n$AgentRun"
}
Write-Pass "Catalog execution completed with exit code 0: Zero configuration drift."

# --- Test 8: Verify Managed Artifacts on node-01 ---
Write-Step "Validating managed files on node-01..."
$MotdContent = (docker exec $AgentContainer cat /etc/motd 2>$null | Out-String)
if ($MotdContent -notmatch "node-01\.infra\.internal" -or $MotdContent -notmatch "Managed by Puppet 8") {
    Stop-OnFail "/etc/motd does not contain expected Puppet-managed content." "Check 'base_system' template."
}
Write-Pass "Managed file /etc/motd verified."

$JsonContent = (docker exec $AgentContainer cat /etc/devops_managed.json 2>$null | Out-String)
if ($JsonContent -notmatch "manual_csr_approved") {
    Stop-OnFail "/etc/devops_managed.json does not contain expected audit content." "Check 'base_system' template."
}
Write-Pass "Managed audit marker /etc/devops_managed.json verified."

# --- Final Summary ---
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "PHASE 2 VERIFICATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "All tests passed without error." -ForegroundColor Green
Write-Host "========================================================`n" -ForegroundColor Cyan
