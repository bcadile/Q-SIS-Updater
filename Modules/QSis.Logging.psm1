$script:LogFilePath = ""

function Initialize-QSisLogging {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogDirectory
    )
    
    if (-not (Test-Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:LogFilePath = Join-Path $LogDirectory "QSisUpdate_$timestamp.log"
    Write-QSisLog "Logging initialized. Log file: $($script:LogFilePath)" -Level "Info"
}

function Write-QSisLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [ValidateSet("Info", "Warning", "Error", "Success", "DryRun")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"
    
    # Write to console
    switch ($Level) {
        "Info" { Write-Host $Message }
        "Success" { Write-Host $Message -ForegroundColor Green }
        "Warning" { Write-Warning $Message }
        "Error" { Write-Host "ERROR: $Message" -ForegroundColor Red }
        "DryRun" { Write-Host "[DRY RUN] $Message" -ForegroundColor Yellow }
    }
    
    # Write to file
    if ($script:LogFilePath) {
        $logLine | Out-File -FilePath $script:LogFilePath -Append -Encoding UTF8
    }
}

Export-ModuleMember -Function Initialize-QSisLogging, Write-QSisLog
