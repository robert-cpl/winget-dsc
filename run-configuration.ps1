## Parameters
param(
    [Parameter(Mandatory=$true)]
    [string]$Type,
    [Parameter(Mandatory=$false)]
    $AutoApprove = $false,
    [Parameter(Mandatory=$false)]
    [string]$GitBranch = "main"
)

$configurationFilePath = "./configurations/configuration.dsc.yaml"

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "winget-config needs to be run as Administrator. Attempting to relaunch."
    Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "iwr -useb https://raw.githubusercontent.com/RobertCopilau/winget-config/main/run-configuration.ps1 | iex"
    break
}

# modules
$header = "https://raw.githubusercontent.com/RobertCopilau/winget-config/$($GitBranch)/configurations/modules/header.yaml"
$footer = "https://raw.githubusercontent.com/RobertCopilau/winget-config/$($GitBranch)/configurations/modules/footer.yaml"

# dsc's
$sharedConfig = "https://raw.githubusercontent.com/RobertCopilau/winget-config/$($GitBranch)/configurations/shared.yaml"
$personalConfig = "https://raw.githubusercontent.com/RobertCopilau/winget-config/$($GitBranch)/configurations/personal.yaml"
$workConfig = "https://raw.githubusercontent.com/RobertCopilau/winget-config/$($GitBranch)/configurations/work.yaml"


If ($Type -match "pers") {
    echo "Using personal DSC configuration."
    $configType = $personalConfig
} Else{
    echo "Using work DSC configuration."
    $configType = $workConfig
}

Get-Content $header, $sharedConfig, $configType, $footer | Set-Content $configurationFilePath

# if ($AutoApprove -eq $true) {
#     winget configuration --file $configurationFilePath --accept-configuration-agreements
# }else{
#     winget configuration --file $configurationFilePath 
# }