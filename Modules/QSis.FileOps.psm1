function Expand-QSisPackage {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ZipPath,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath
    )
    
    if (-not (Test-Path $ZipPath)) {
        throw "Update package not found: $ZipPath"
    }

    if (Test-Path $DestinationPath) {
        Remove-Item -Path $DestinationPath -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    
    Write-QSisLog "Extracting $ZipPath to $DestinationPath"
    Expand-Archive -Path $ZipPath -DestinationPath $DestinationPath -Force
}

function Backup-QSisWebFiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$BackupDirectory,
        
        [Parameter(Mandatory=$true)]
        [string]$ServerName
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path -Path $BackupDirectory -ChildPath "${ServerName}_WebBackup_$timestamp"
    
    if (-not (Test-Path $BackupDirectory)) {
        New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
    }
    
    Write-QSisLog "Backing up files from $SourcePath to $backupPath"
    if (Test-Path $SourcePath) {
        # Use robocopy with 8 threads for faster network operations, retrying up to 3 times
        robocopy $SourcePath $backupPath /E /MT:8 /R:3 /W:5 /NFL /NDL /NJH /NJS /NP | Out-Null
        
        # Robocopy exit codes under 8 indicate success
        if ($LASTEXITCODE -lt 8) {
            Write-QSisLog "Backup completed successfully: $backupPath" -Level Success
            return $true
        } else {
            Write-QSisLog "Backup failed using robocopy (Exit Code: $LASTEXITCODE)" -Level Warning
            return $false
        }
    } else {
        Write-QSisLog "Backup source path does not exist: $SourcePath" -Level Warning
        return $false
    }
}

function Deploy-QSisWebFiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath
    )
    
    if (-not (Test-Path $SourcePath)) {
        throw "Source directory for deployment not found: $SourcePath"
    }

    if (-not (Test-Path $DestinationPath)) {
        Write-QSisLog "Creating destination directory: $DestinationPath"
        New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    }
    
    Write-QSisLog "Deploying files to $DestinationPath"
    Copy-Item -Path "$SourcePath\*" -Destination $DestinationPath -Recurse -Force
}

Export-ModuleMember -Function Expand-QSisPackage, Backup-QSisWebFiles, Deploy-QSisWebFiles
