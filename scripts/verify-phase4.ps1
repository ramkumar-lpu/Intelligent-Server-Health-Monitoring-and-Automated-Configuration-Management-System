# Phase 4 End-to-End Integration Verification Script
# Validates Terraform nodes (02-10), Compose infra, Puppet CA & roles, Nagios 10-node monitoring, and Jenkins pipeline assets

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "PHASE 4: FULL 10-NODE INFRASTRUCTURE & MONITORING CHECK" -ForegroundColor Cyan
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

$expectedIPs = @{
    "puppet-server" = "10.240.0.10"
    "nagios-server" = "10.240.0.20"
    "node-01"       = "10.240.0.101"
    "node-02"       = "10.240.0.102"
    "node-03"       = "10.240.0.103"
    "node-04"       = "10.240.0.104"
    "node-05"       = "10.240.0.105"
    "node-06"       = "10.240.0.106"
    "node-07"       = "10.240.0.107"
    "node-08"       = "10.240.0.108"
    "node-09"       = "10.240.0.109"
    "node-10"       = "10.240.0.110"
}

# 1. All 12 containers running and healthy
Assert-Check "All 12 containers (infra + node-01..10) are running and healthy" {
    foreach ($name in $expectedIPs.Keys) {
        $st = docker inspect $name --format '{{.State.Status}}:{{.State.Health.Status}}' 2>&1 | Out-String
        if ($st -notmatch "running:healthy") { return $false }
    }
    return $true
}

# 2. All static IP addresses match architecture table
Assert-Check "All 12 containers hold their expected static IPv4 addresses" {
    foreach ($kv in $expectedIPs.GetEnumerator()) {
        $ip = docker inspect $kv.Key --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>&1 | Out-String
        if ($ip.Trim() -ne $kv.Value) { return $false }
    }
    return $true
}

# 3. Terraform manages exactly node-02..10 (9 resources)
Assert-Check "Terraform state manages exactly 9 containers (node-02..10)" {
    $checkedPaths = @()
    $statePath = $null

    if (-not [string]::IsNullOrWhiteSpace($env:TF_STATE_PATH)) {
        $checkedPaths += $env:TF_STATE_PATH
        if (Test-Path -LiteralPath $env:TF_STATE_PATH) {
            $statePath = $env:TF_STATE_PATH
        } else {
            Write-Host "    [DIAG] TF_STATE_PATH is set but not found: $($env:TF_STATE_PATH)" -ForegroundColor Yellow
            return $false
        }
    } else {
        $candidates = @(
            (Join-Path $PSScriptRoot "..\terraform\terraform.tfstate"),
            "D:\Devops_Project\terraform\terraform.tfstate"
        )
        foreach ($candidate in $candidates) {
            $checkedPaths += $candidate
            if (Test-Path -LiteralPath $candidate) {
                $statePath = $candidate
                break
            }
        }
    }

    if (-not $statePath) {
        Write-Host "    [DIAG] No Terraform state file found. Checked: $($checkedPaths -join '; ')" -ForegroundColor Yellow
        return $false
    }

    $tfState = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
    $containerRes = $tfState.resources | Where-Object { $_.type -eq 'docker_container' -and $_.name -eq 'this' }
    if (-not $containerRes) {
        Write-Host "    [DIAG] Missing docker_container.this resource in state: $statePath" -ForegroundColor Yellow
        return $false
    }

    $expectedKeys = @('node-02', 'node-03', 'node-04', 'node-05', 'node-06', 'node-07', 'node-08', 'node-09', 'node-10')
    $actualKeys = @($containerRes.instances | ForEach-Object { [string]$_.index_key } | Sort-Object)
    $diff = Compare-Object -ReferenceObject $expectedKeys -DifferenceObject $actualKeys
    if ($diff -or $actualKeys.Count -ne 9) {
        Write-Host "    [DIAG] Unexpected container keys in $($statePath): $($actualKeys -join ', ')" -ForegroundColor Yellow
        return $false
    }
    return $true
}

# 4. Puppet CA has signed certificates for all 10 managed nodes and autosign=false
Assert-Check "Puppet CA signed all 10 managed nodes with autosign=false" {
    $ca = docker exec puppet-server puppetserver ca list --all 2>&1 | Out-String
    $conf = docker exec puppet-server grep -E '^autosign\s*=\s*false' /etc/puppetlabs/puppet/puppet.conf 2>&1 | Out-String
    if ($conf -notmatch 'autosign\s*=\s*false') { return $false }
    for ($i = 1; $i -le 10; $i++) {
        $fqdn = ("node-{0:D2}.infra.internal" -f $i)
        if ($ca -notmatch [regex]::Escape($fqdn)) { return $false }
    }
    return ($ca -notmatch 'Requested Certificates:')
}

# 5. Role-specific services running on all 10 nodes
Assert-Check "Role-specific services are running on node-01 through node-10" {
    $checks = @(
        @("node-01", "pgrep -x nginx >/dev/null"),
        @("node-02", "pgrep -x nginx >/dev/null"),
        @("node-03", "/etc/init.d/postgresql status >/dev/null 2>&1"),
        @("node-04", "/etc/init.d/postgresql status >/dev/null 2>&1"),
        @("node-05", "start-stop-daemon --status --pidfile /run/nodejs-health.pid"),
        @("node-06", "start-stop-daemon --status --pidfile /run/nodejs-health.pid"),
        @("node-07", "pgrep -x redis-server >/dev/null"),
        @("node-08", "pgrep -x redis-server >/dev/null"),
        @("node-09", "start-stop-daemon --status --pidfile /run/devops-worker.pid"),
        @("node-10", "pgrep -x cron >/dev/null && test -x /usr/local/bin/infra-backup-check.sh")
    )
    foreach ($pair in $checks) {
        docker exec $pair[0] sh -c $pair[1] *> $null
        if ($LASTEXITCODE -ne 0) { return $false }
    }
    return $true
}

# 6. Nagios pre-flight validation succeeds with 0 errors and 0 warnings
Assert-Check "Nagios pre-flight validation passes (0 errors, 0 warnings)" {
    $val = docker exec nagios-server /opt/nagios/bin/nagios -v /opt/nagios/etc/nagios.cfg 2>&1 | Out-String
    return (($val -match "Total Errors:\s+0") -and ($val -match "Total Warnings:\s+0"))
}

# 7. Nagios monitors all 10 managed nodes via NRPE (mem & cpu cgroup)
Assert-Check "Nagios server reaches NRPE check_mem_cgroup and check_cpu_cgroup on all 10 nodes" {
    for ($i = 1; $i -le 10; $i++) {
        $ip = "10.240.0." + (100 + $i)
        $m = docker exec nagios-server /opt/nagios/libexec/check_nrpe -H $ip -c check_mem_cgroup 2>&1 | Out-String
        $c = docker exec nagios-server /opt/nagios/libexec/check_nrpe -H $ip -c check_cpu_cgroup 2>&1 | Out-String
        if ($m -notmatch "^(OK|WARNING|CRITICAL) -" -or $c -notmatch "^(OK|WARNING|CRITICAL) -") { return $false }
    }
    return $true
}

# 8. Jenkins Windows Service is Running and Jenkinsfile exists
Assert-Check "Jenkins Windows Service is Running and jenkins/Jenkinsfile exists" {
    $svc = Get-Service -Name '*jenkins*' -ErrorAction SilentlyContinue
    $jf = Test-Path (Join-Path $PSScriptRoot "..\jenkins\Jenkinsfile")
    return ($svc -and $svc.Status -eq 'Running' -and $jf)
}

$summaryColor = "Green"
if ($Failed -gt 0) { $summaryColor = "Red" }
Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Summary: Passed: $Passed | Failed: $Failed" -ForegroundColor $summaryColor
Write-Host "==========================================================" -ForegroundColor Cyan

if ($Failed -gt 0) { exit 1 }
exit 0
