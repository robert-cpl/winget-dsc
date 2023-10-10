## Parameters
param(
    [Parameter(Mandatory=$true)]
    [string]$Type,
    [Parameter(Mandatory=$false)]
    $AutoApprove = $false,
    [Parameter(Mandatory=$false)]
    [string]$GitBranch = "main"
)

$configurationFolderPath = "./configurations"
echo "Testing folder path to $configurationFolderPath."
if (!(Test-Path $configurationFolderPath)) {
    echo "Creating configuration folder to path $configurationFolderPath."
    New-Item -ItemType Directory -Path $configurationFolderPath
}

$configurationFileName = "configuration.dsc.yaml"
$configurationFilePath = "$configurationFolderPath/$configurationFileName"

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "winget-config needs to be run as Administrator. Attempting to relaunch."
    Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "iwr -useb https://raw.githubusercontent.com/RobertCopilau/winget-config/main/run-configuration.ps1 | iex"
    break
}

# modules
$header = iwr -useb "https://raw.githubusercontent.com/RobertCopilau/winget-config/$($GitBranch)/configurations/modules/header.yaml"
$headerContent = $header.Content
$footer = iwr -useb "https://raw.githubusercontent.com/RobertCopilau/winget-config/$($GitBranch)/configurations/modules/footer.yaml"
$footerContent = $footer.Content

# dsc's
$sharedConfig = iwr -useb "https://raw.githubusercontent.com/RobertCopilau/winget-config/$($GitBranch)/configurations/shared.yaml"
$sharedConfigContent = $sharedConfig.Content
$personalConfig = iwr -useb "https://raw.githubusercontent.com/RobertCopilau/winget-config/$($GitBranch)/configurations/personal.yaml"
$personalConfigContent = $personalConfig.Content
$workConfig = iwr -useb "https://raw.githubusercontent.com/RobertCopilau/winget-config/$($GitBranch)/configurations/work.yaml"
$workConfigContent = $workConfig.Content

If ($Type -match "pers") {
    echo "Using personal DSC configuration."
    $configType = $personalConfigContent
} Else{
    echo "Using work DSC configuration."
    $configType = $workConfigContent
}

$headerContent, $sharedConfigContent, $configTypeCOntent, $footerContent | Set-Content -Path $configurationFilePath

if ($AutoApprove -eq $true) {
    winget configuration --file $configurationFilePath --accept-configuration-agreements
}else{
    winget configuration --file $configurationFilePath 
}

Cleanup
Remove-Item $configurationFilePath