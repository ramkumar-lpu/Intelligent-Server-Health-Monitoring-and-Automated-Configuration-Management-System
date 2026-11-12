# Stage 4B / Phase 3 Nagios Core Verification Script
# Validates Nagios configuration, NRPE connectivity, and service check definitions

[CmdletBinding()]
param(
    [string]$NagiosHost = "localhost",
    [int]$NagiosPort = 8085,
    [string]$Node01IP = "10.240.0.101",
    [string]$NagiosIP = "10.240.0.20"
)

$ErrorActionPreference = "Continue"
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "PHASE 3: NAGIOS CORE & NRPE MONITORING VERIFICATION" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$Passed = 0
$Failed = 0

function Assert-Check {
    param(
        [string]$Description,
        [scriptblock]$Test
    )
    Write-Host -NoNewline "[TEST] $Description... "
    try {
        $result = & $Test
        if ($result -eq $true) {
            Write-Host "PASSED" -ForegroundColor Green
            $script:Passed++
        } else {
            Write-Host "FAILED" -ForegroundColor Red
            $script:Failed++
        }
    } catch {
        Write-Host "FAILED ($($_.Exception.Message))" -ForegroundColor Red
        $script:Failed++
    }
}

# 1. Verify Docker network
Assert-Check "Docker network devops-infra-net exists" {
    $net = docker network inspect devops-infra-net 2>&1 | Out-String
    return ($net -match "10.240.0.0/16")
}

# 2. Verify node-01 is running and healthy
Assert-Check "Container node-01 is running and healthy" {
    $status = docker inspect node-01 --format '{{.State.Status}}:{{.State.Health.Status}}' 2>&1
    return ($status -match "running:healthy")
}

# 3. Verify puppet-server is running and healthy
Assert-Check "Container puppet-server is running and healthy" {
    $status = docker inspect puppet-server --format '{{.State.Status}}:{{.State.Health.Status}}' 2>&1
    return ($status -match "running:healthy")
}

# 4. Verify node-01 NRPE listening on port 5666
Assert-Check "node-01 is listening on port 5666" {
    $ports = docker exec node-01 ss -tlpn 2>&1 | Out-String
    return ($ports -match ":5666")
}

# 5. Verify node-01 NRPE allowed_hosts includes Nagios IP
Assert-Check "node-01 nrpe.cfg contains Nagios IP (10.240.0.20)" {
    $cfg = docker exec node-01 grep "allowed_hosts" /etc/nagios/nrpe.cfg 2>&1 | Out-String
    return ($cfg -match "10\.240\.0\.20")
}

# 6. Verify node-01 security settings
Assert-Check "node-01 nrpe.cfg enforces dont_blame_nrpe=0" {
    $cfg = docker exec node-01 grep "dont_blame_nrpe=0" /etc/nagios/nrpe.cfg 2>&1 | Out-String
    return ($cfg -match "dont_blame_nrpe=0")
}

# 7. Check Nagios configuration syntax validity
Assert-Check "Nagios configuration pre-flight validation succeeds" {
    $val = docker exec nagios-server /opt/nagios/bin/nagios -v /opt/nagios/etc/nagios.cfg 2>&1 | Out-String
    return ($val -match "Total Errors:\s+0")
}

$summaryColor = "Green"
if ($Failed -gt 0) { $summaryColor = "Red" }
Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Summary: Passed: $Passed | Failed: $Failed" -ForegroundColor $summaryColor
Write-Host "==========================================================" -ForegroundColor Cyan

if ($Failed -gt 0) {
    exit 1
}
exit 0
