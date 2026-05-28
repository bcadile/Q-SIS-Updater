function Get-QSisSqlScripts {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SqlDirectory
    )
    
    if (-not (Test-Path $SqlDirectory)) {
        Write-QSisLog "SQL directory not found: $SqlDirectory. Skipping SQL execution." -Level Warning
        return @()
    }
    
    # Get all .sql files and sort them alphabetically to ensure execution order
    $scripts = Get-ChildItem -Path $SqlDirectory -Filter "*.sql" -File | Sort-Object Name
    return $scripts
}

function Get-QSisConnectionString {
    param (
        [Parameter(Mandatory=$true)]
        [object]$DatabaseConfig
    )
    
    $connectionString = $DatabaseConfig.ConnectionString
    if ([string]::IsNullOrWhiteSpace($connectionString)) {
        if ($DatabaseConfig.Authentication -eq "Windows") {
            $connectionString = "Server=$($DatabaseConfig.Server);Database=$($DatabaseConfig.Name);Integrated Security=True;TrustServerCertificate=True"
        } else {
            $password = $DatabaseConfig.Password
            if ($password -like "file://*") {
                $relativePath = $password -replace "^file://", ""
                $scriptRoot = Split-Path $PSScriptRoot -Parent
                $absolutePath = if ([System.IO.Path]::IsPathRooted($relativePath)) {
                    $relativePath
                } else {
                    Join-Path $scriptRoot $relativePath
                }
                
                if (Test-Path $absolutePath) {
                    try {
                        $encrypted = Get-Content -Path $absolutePath -Raw
                        $secureString = $encrypted | ConvertTo-SecureString
                        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
                        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                    } catch {
                        Write-QSisLog "Failed to decrypt password file: $absolutePath. Error: $_" -Level Warning
                        $password = ""
                    }
                } else {
                    Write-QSisLog "Password file not found: $absolutePath" -Level Warning
                    $password = ""
                }
            }
            $connectionString = "Server=$($DatabaseConfig.Server);Database=$($DatabaseConfig.Name);User Id=$($DatabaseConfig.Username);Password=$password;TrustServerCertificate=True"
        }
    }
    return $connectionString
}

function Test-QSisSqlConnection {
    param (
        [Parameter(Mandatory=$true)]
        [object]$DatabaseConfig
    )
    
    $connectionString = Get-QSisConnectionString -DatabaseConfig $DatabaseConfig
    
    Write-QSisLog "Testing SQL Connection to $($DatabaseConfig.Server)\$($DatabaseConfig.Name)..." -Level DryRun
    
    $connection = $null
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        Write-QSisLog "Successfully connected to SQL database: $($DatabaseConfig.Name)" -Level Success
        return $true
    } catch {
        Write-QSisLog "Failed to connect to SQL Database $($DatabaseConfig.Name). Error: $_" -Level Warning
        return $false
    } finally {
        if ($null -ne $connection) { $connection.Dispose() }
    }
}

function Invoke-QSisSqlScript {
    param (
        [Parameter(Mandatory=$true)]
        [object]$DatabaseConfig,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 600
    )
    
    $scriptName = Split-Path -Leaf $ScriptPath
    Write-QSisLog "Executing SQL Script: $scriptName on $($DatabaseConfig.Server)\$($DatabaseConfig.Name)"
    
    $connectionString = Get-QSisConnectionString -DatabaseConfig $DatabaseConfig
    
    $connection = $null
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        
        $scriptContent = Get-Content -Path $ScriptPath -Raw
        
        # Split script on GO batches
        $batches = $scriptContent -split '(?im)^\s*GO\s*$'
        
        foreach ($batch in $batches) {
            if (-not [string]::IsNullOrWhiteSpace($batch)) {
                $command = $null
                try {
                    $command = $connection.CreateCommand()
                    $command.CommandText = $batch
                    $command.CommandTimeout = $TimeoutSeconds
                    $command.ExecuteNonQuery() | Out-Null
                } finally {
                    # Dispose the command regardless of success or failure
                    if ($null -ne $command) { $command.Dispose() }
                }
            }
        }
        
        Write-QSisLog "Successfully executed: $scriptName" -Level Success
        return $true
    }
    catch {
        Write-QSisLog "Failed to execute script $scriptName : $_" -Level Warning
        throw
    }
    finally {
        # Guaranteed cleanup — runs on success, failure, and even PowerShell termination signals
        if ($null -ne $connection) { $connection.Dispose() }
    }
}

Export-ModuleMember -Function Get-QSisSqlScripts, Invoke-QSisSqlScript, Test-QSisSqlConnection
