#set params
param (
    [string]$envPrompt = $( Read-Host "Which environment are you updating, production(p), testing(t) or reporting(r)?"
     )
 )

#retrieve and parse config values
Get-Content ".\config.txt" | foreach-object -begin {$h=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }

#set configs to vars
$conf_training = $h.training
$conf_production = $h.production
$conf_reporting = $h.reporting

$conf_testServers = $h.testServers 
$conf_prodServers = $h.prodServers 
$conf_reportServers = $h.reportServers 

$conf_payload = $h.payloadPath

if ($envPrompt -eq "t") {
    "Testing environment set"
    #$computers = Get-Content ".\servers\testing.txt"
    $computers = Get-Content $conf_testServers
}
if ($envPrompt -eq "p") {
    "Production environment set"
    #$computers = Get-Content ".\servers\production.txt"
    $computers = Get-Content $conf_prodServers
}

if ($envPrompt -eq "r") {
    "Report environment set"
    $computers = Get-Content $conf_reportServers
}

# Set source location
$source = $conf_payload

# Set destination
if ($envPrompt -eq 't'){
    #$dest = "c$\training\"
    $dest = $conf_training
}

if ($envPrompt -eq 'p'){
    #$dest = "c$\production\"
    $dest = $conf_production
}

if ($envPrompt -eq 'r'){
    #$dest = "c$\production\"
    $dest = $conf_reporting
}

#confirm processing of production environment
if ($envPrompt -eq "p" -or $envPrompt -eq "r" ){
    $envConf = Read-Host -Prompt 'Are you sure you want to copy to your production environment? (y/n)'
    if ($envConf -eq 'y'){
        $execute = "y"
    } else {
        $execute = "n"
    }
} else {
    $execute = "y"}

#Execute copy
if ($execute -eq "y") {
    foreach ($computer in $computers) {
        if (test-Connection -Cn $computer -quiet) {
            Copy-Item $source -Destination \\$computer\$dest -Recurse -Force -Verbose
            "Files copied to $computer..."
        } else {
            "$computer is not online"
        }
    }
    "...Process complete!"
} else {
    "Process aborted!"
}