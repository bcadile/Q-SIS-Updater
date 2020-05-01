#set params
param (
    [string]$envPrompt = $( Read-Host "Which environment are you updating, production(p), testing(t) or reporting(r)?"
     )
 )

#retrieve and parse config values
Get-Content ".\config.txt" | foreach-object -begin {$h=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }

#set configs to vars
##environment defined
$conf_training = $h.training
$conf_production = $h.production
$conf_reporting = $h.reporting
##server definition
$conf_testServers = $h.testServers 
$conf_prodServers = $h.prodServers 
$conf_reportServers = $h.reportServers 
##payload location
$conf_payload = $h.payloadPath
##copy mode
$conf_verbose = $h.verbose
##logging
$conf_logging = $h.logging 
$conf_logpath = $h.logPath

#logging function
function write_log {
    param($msg)
    if ($conf_logging -eq "y"){
        "$(Get-Date -Format G) : $msg" | Out-File -FilePath $conf_logpath -Append -Force
    } else {
        "$(Get-Date -Format G) : $msg"
    }
}

#logging begins
write_log  "SIS Update Script Starting...  "
if ($conf_verbose -eq "y"){
    write_log "Verbose logging is enabled"
}

#machine destinations are set
if ($envPrompt -eq "t") {
    write_log "Testing environment set..."
    $computers = Get-Content $conf_testServers
}
if ($envPrompt -eq "p") {
    write_log "Production environment set..."
    $computers = Get-Content $conf_prodServers
}

if ($envPrompt -eq "r") {
    write_log "Report environment set..."
    $computers = Get-Content $conf_reportServers
}

# process source location for execution
$source = $conf_payload

# process destination for execution
if ($envPrompt -eq 't'){
    $dest = $conf_training
}
if ($envPrompt -eq 'p'){
    $dest = $conf_production
}
if ($envPrompt -eq 'r'){
    $dest = $conf_reporting
}

#confirm processing of production environment - just a double check
if ($envPrompt -eq "p" -or $envPrompt -eq "r" ){
    $envConf = Read-Host -Prompt 'Are you sure you want to copy to your production environment? (y/n)'
    if ($envConf -eq 'y'){
        $execute = "y"
        write_log "Updating production environment confirmed"
    } else {
        $execute = "n"
    }
} else {
    $execute = "y"}

#Execute copy process
if ($execute -eq "y") {
    foreach ($computer in $computers) {
        if (test-Connection -Cn $computer -quiet) {
            if ($conf_verbose -eq "y"){
                try {
                    $copy_output = Copy-Item $source -Destination \\$computer\$dest -Recurse -Force -Verbose 4>&1 
                    write_log $copy_output
                    #Error handling
                    If($x.ExitCode -ne 0 -and $x.ExitCode -ne 3010 -and $x.ExitCode -ne $null){
                        $ExitCode = $x.ExitCode
                        Write-Log "Exit Code: $ExitCode"
                        Exit 2
                    }                    
                }
                catch {
                    #error handling
                    Write-Log "There was error starting the process for $AppName"
                    $ErrorMessage = $_
                    Write-Log "Error Message: `n$ErrorMessage"
                    Exit 1
                }
            } else {
                try {
                    $copy_output = Copy-Item $source -Destination \\$computer\$dest -Recurse -Force 4>&1 
                    write_log $copy_output
                    #Error handling
                    If($x.ExitCode -ne 0 -and $x.ExitCode -ne 3010 -and $x.ExitCode -ne $null){
                        $ExitCode = $x.ExitCode
                        Write-Log "Exit Code: $ExitCode"
                        Exit 2
                    }
                }
                catch {
                    #error handling
                    Write-Log "There was error starting the process for $AppName"
                    $ErrorMessage = $_
                    Write-Log "Error Message: `n$ErrorMessage"
                    Exit 1
                }
            }
            write_log "Files successfully copied to $computer..."
        } else {
            write_log "$computer is not online!"
        }
    }
    write_log "...Process complete!"
} else {
    write_log "Process aborted by user!"
}