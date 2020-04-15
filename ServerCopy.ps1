param (
    [string]$envPrompt = $( Read-Host "Which environment are you updating, production(p) or testing(t)?"
     )
 )

#Establish environment and gather machine list
 #$envPrompt = Read-Host -Prompt 'Which environment are you updating, production(p) or testing(t)?'
if ($envPrompt -eq "p") {
    "Production environment set"
    $computers = Get-Content ".\servers\production.txt"
}
if ($envPrompt -eq "t") {
    "Testing environment set"
    $computers = Get-Content ".\servers\testing.txt"
}

# Set source location
$source = ".\payloads\*"

# Set destination
if ($envPrompt -eq 't'){
    $dest = "c$\training\"
}

if ($envPrompt -eq 'p'){
    $dest = "c$\production\"
}

#confirm processing of production environment
if ($envPrompt -eq "p"){
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
            Copy-Item $source -Destination \\$computer\$dest -Recurse -Force
            "Files copied to $computer..."
        } else {
            "$computer is not online"
        }
    }
    "...Process complete!"
} else {
    "Process aborted!"
}