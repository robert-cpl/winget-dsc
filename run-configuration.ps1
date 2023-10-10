## Parameters
param(
    [Parameter(Mandatory=$true)]
    [string]$Type,
    [Parameter(Mandatory=$false)]
    $AutoApprove = $false
)

$configurationFilePath = "./configurations/configuration.dsc.yaml"

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "winget-config needs to be run as Administrator. Attempting to relaunch."
    Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "iwr -useb https://raw.githubusercontent.com/RobertCopilau/winget-config/main/run-configuration.ps1 | iex"
    break
}

# modules
$header = "./configurations/modules/header.yaml"
$footer = "./configurations/modules/footer.yaml"

# dsc's
$sharedConfig = "./configurations/shared.yaml"
$personalConfig = "./configurations/personal.yaml"
$workConfig = "./configurations/work.yaml"


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