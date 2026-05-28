<#
.SYNOPSIS
    Deploys a Q-SIS Update Package.

.DESCRIPTION
    Extracts a ZIP package, backs up current files, deploys new web files via UNC, 
    and executes SQL scripts.

.PARAMETER UpdatePackagePath
    Path to the ZIP file containing the update.

.PARAMETER ConfigPath
    Path to the config.json file. Defaults to .\config.json in the script directory.

.PARAMETER DryRun
    If specified, validates the package and config but makes no changes.

.PARAMETER Force
    If specified, allows deployment to proceed even if a backup fails or cannot be created.
    Use with caution — deploying without a backup removes your rollback safety net.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$UpdatePackagePath,

    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "$PSScriptRoot\config.json",

    [switch]$DryRun,

    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Import Custom Modules
Import-Module (Join-Path $PSScriptRoot "Modules\QSis.Logging.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "Modules\QSis.FileOps.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "Modules\QSis.SqlOps.psm1") -Force

# 1. Load Configuration
if (-not (Test-Path $ConfigPath)) {
    throw "Configuration file not found: $ConfigPath"
}
$config = Get-Content -Path $ConfigPath | ConvertFrom-Json

# Initialize Logging
$logDir = if ($config.Settings.LogDirectory) { $config.Settings.LogDirectory } else { "$PSScriptRoot\Logs" }
Initialize-QSisLogging -LogDirectory $logDir

Write-QSisLog "========================================="
Write-QSisLog " Q-SIS CLI Updater "
Write-QSisLog "========================================="
Write-QSisLog "Loading configuration from: $ConfigPath"

# 2. Package Intake & Extraction
if (-not (Test-Path $UpdatePackagePath)) {
    Write-QSisLog "Update package not found: $UpdatePackagePath" -Level Error
    throw "Update package not found: $UpdatePackagePath"
}

$stagingDir = Join-Path $env:TEMP "QSisStaging_$(Get-Random)"

if ($DryRun) {
    Write-QSisLog "Would extract $UpdatePackagePath to $stagingDir" -Level DryRun
} else {
    Expand-QSisPackage -ZipPath $UpdatePackagePath -DestinationPath $stagingDir
}

# Define extracted paths
$appSourcePath = Join-Path $stagingDir "Applications"
if (-not (Test-Path $appSourcePath)) {
    # Fallback to the root of the extracted ZIP if there's no Applications folder
    $appSourcePath = $stagingDir
}
$sqlSourcePath = Join-Path $stagingDir "SQL"

# Track deployment results
$deploymentResults = @()

# 3. File Deployment
Write-QSisLog "`n--- Web File Deployment ---"
foreach ($server in $config.TargetServers) {
    if ($server.Type -eq "Web") {
        Write-QSisLog "Processing Target Server: $($server.Name)"
        
        $result = [PSCustomObject]@{
            Target  = $server.Name
            Type    = "Files"
            Status  = "Pending"
            Message = ""
        }

        if ($DryRun) {
            Write-QSisLog "Would backup $($server.DeploymentPath) to $($config.Settings.BackupDirectory)" -Level DryRun
            Write-QSisLog "Would deploy files from $appSourcePath to $($server.DeploymentPath)" -Level DryRun
            $result.Status = "DryRun"
        } else {
            # Step 1: Attempt backup
            $backupSuccess = $false
            try {
                $backupSuccess = Backup-QSisWebFiles -SourcePath $server.DeploymentPath -BackupDirectory $config.Settings.BackupDirectory -ServerName $server.Name
            } catch {
                Write-QSisLog "Backup failed for $($server.Name): $($_.Exception.Message)" -Level Warning
            }

            # Step 2: Gate deployment on backup result unless -Force is set
            if (-not $backupSuccess -and -not $Force) {
                $result.Status = "Skipped"
                $result.Message = "Backup failed or was skipped. Use -Force to deploy without a backup."
                Write-QSisLog "Skipping deployment to $($server.Name) — no backup was created. Run with -Force to override." -Level Warning
            } else {
                if (-not $backupSuccess -and $Force) {
                    Write-QSisLog "WARNING: Deploying to $($server.Name) without a confirmed backup (-Force was used)." -Level Warning
                }
                # Step 3: Deploy
                try {
                    Deploy-QSisWebFiles -SourcePath $appSourcePath -DestinationPath $server.DeploymentPath
                    $result.Status = "Success"
                } catch {
                    $result.Status = "Failed"
                    $result.Message = $_.Exception.Message
                    Write-QSisLog "FAILED deploying to $($server.Name): $($_.Exception.Message)" -Level Warning
                }
            }
        }

        $deploymentResults += $result
    }
}

# 4. SQL Execution
Write-QSisLog "`n--- SQL Execution ---"
$sqlScriptsFound = $false
if (Test-Path $sqlSourcePath) {
    $scripts = Get-QSisSqlScripts -SqlDirectory $sqlSourcePath
    if ($scripts.Count -gt 0) { $sqlScriptsFound = $true }
}

if ($DryRun) {
    # Test SQL connections for all configured databases since ZIP might not be extracted in staging
    if ($config.Databases -and $config.Databases.Count -gt 0) {
        foreach ($db in $config.Databases) {
            $connResult = [PSCustomObject]@{
                Target  = "$($db.Name) on $($db.Server)"
                Type    = "SQL Connection Test"
                Status  = "DryRun"
                Message = ""
            }
            $testSuccess = Test-QSisSqlConnection -DatabaseConfig $db
            if (-not $testSuccess) {
                $connResult.Message = "Connection test failed."
            }
            $deploymentResults += $connResult
            
            if ($sqlScriptsFound) {
                foreach ($script in $scripts) {
                    $deploymentResults += [PSCustomObject]@{
                        Target  = "$($db.Name) on $($db.Server)"
                        Type    = "SQL: $($script.Name)"
                        Status  = "DryRun"
                        Message = "Would execute script"
                    }
                }
            }
        }
    }
    if (-not $sqlScriptsFound) {
        Write-QSisLog "No SQL scripts found to preview." -Level Warning
    }
} else {
    if ($sqlScriptsFound) {
        foreach ($db in $config.Databases) {
            Write-QSisLog "Processing Target Database: $($db.Name) on $($db.Server)"
            
            # Test connectivity first as a gate
            $connectionValid = Test-QSisSqlConnection -DatabaseConfig $db
            
            foreach ($script in $scripts) {
                $result = [PSCustomObject]@{
                    Target  = "$($db.Name) on $($db.Server)"
                    Type    = "SQL: $($script.Name)"
                    Status  = "Pending"
                    Message = ""
                }

                if (-not $connectionValid) {
                    $result.Status = "Failed"
                    $result.Message = "Skipped because connection test failed."
                    Write-QSisLog "Skipping execution of $($script.Name) on $($db.Name) due to connection failure." -Level Warning
                } else {
                    try {
                        Invoke-QSisSqlScript -DatabaseConfig $db -ScriptPath $script.FullName -TimeoutSeconds $config.Settings.SqlExecutionTimeoutSeconds
                        $result.Status = "Success"
                    } catch {
                        $result.Status = "Failed"
                        $result.Message = $_.Exception.Message
                        Write-QSisLog "FAILED executing $($script.Name) on $($db.Name): $($_.Exception.Message)" -Level Warning
                    }
                }
                $deploymentResults += $result
            }
        }
    } else {
        Write-QSisLog "No SQL scripts found in the update package." -Level Warning
    }
}

# 5. Cleanup
if (Test-Path $stagingDir) {
    Write-QSisLog "`nCleaning up staging directory..."
    Remove-Item -Path $stagingDir -Recurse -Force
}

# 6. Deployment Summary Report
Write-QSisLog "`n========================================="
Write-QSisLog " Deployment Summary "
Write-QSisLog "========================================="

$failedCount = ($deploymentResults | Where-Object { $_.Status -eq "Failed" }).Count
$skippedCount = ($deploymentResults | Where-Object { $_.Status -eq "Skipped" }).Count
$successCount = ($deploymentResults | Where-Object { $_.Status -eq "Success" }).Count
$dryRunCount = ($deploymentResults | Where-Object { $_.Status -eq "DryRun" }).Count

foreach ($r in $deploymentResults) {
    $icon = switch ($r.Status) {
        "Success" { "[OK]" }
        "Failed"  { "[FAIL]" }
        "Skipped" { "[SKIP]" }
        "DryRun"  { "[DRY]" }
        default   { "[??]" }
    }
    $line = "$icon $($r.Target) | $($r.Type)"
    if ($r.Message) { $line += " | $($r.Message)" }

    if ($r.Status -eq "Failed") {
        Write-QSisLog $line -Level Warning
    } elseif ($r.Status -eq "Skipped") {
        Write-QSisLog $line -Level Warning
    } elseif ($r.Status -eq "Success") {
        Write-QSisLog $line -Level Success
    } else {
        Write-QSisLog $line
    }
}

Write-QSisLog "-----------------------------------------"

if ($failedCount -gt 0 -or $skippedCount -gt 0) {
    Write-QSisLog "Result: $failedCount FAILED, $skippedCount SKIPPED, $successCount succeeded." -Level Warning
    Write-QSisLog "Review the log and affected targets above. Some servers may be running a different version." -Level Warning
    exit 1
} elseif ($dryRunCount -gt 0) {
    Write-QSisLog "Dry run complete. No changes were made." -Level Success
} else {
    Write-QSisLog "All $successCount deployment steps completed successfully." -Level Success
}
