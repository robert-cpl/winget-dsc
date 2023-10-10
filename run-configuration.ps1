# Local development variables
$isLocalDevelopment = $false

# User Input
$dscTypeUserInput = Read-Host "Enter DSC Type (personal/work) `r`nPress enter for default (personal):"
$autoApproveUserInput = Read-Host "DSC will be applied automatically. Do you want to continue? (y/n) `r`nPress enter for default (n):"

$dscType = if ($dscTypeUserInput -eq "" -or $dscTypeUserInput -like "per") {"personal"} else {"work"}
$autoApprove = if ($autoApprove -eq "" -or $autoApprove -eq "y") {$false} else {$true}

# Configuration file path setup
$configurationFolderPath = "./configurations"
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

# Modules
$fileFolderPath = if ($isLocalDevelopment) {"./configurations"} else {"https://raw.githubusercontent.com/RobertCopilau/winget-config/main/configurations"}
$header = iwr -useb "$fileFolderPath/modules/header.yaml"
$headerContent = $header.Content
$footer = iwr -useb "$fileFolderPath/modules/footer.yaml"
$footerContent = $footer.Content

# DSC's
$sharedConfig = iwr -useb "$fileFolderPath/shared.yaml"
$sharedConfigContent = $sharedConfig.Content
$personalConfig = iwr -useb "$fileFolderPath/personal.yaml"
$personalConfigContent = $personalConfig.Content
$workConfig = iwr -useb "$fileFolderPath/work.yaml"
$workConfigContent = $workConfig.Content

if ($dscType -eq "personal") {
    echo "Using personal DSC configuration."
    $configType = $personalConfigContent
} else{
    echo "Using work DSC configuration."
    $configType = $workConfigContent
}

# Build the DSC configuration file
$headerContent, $sharedConfigContent, $configTypeCOntent, $footerContent | Set-Content -Path $configurationFilePath

# if ($autoApprove -eq $true) {
#     winget configuration --file $configurationFilePath --accept-configuration-agreements
# }else{
#     winget configuration --file $configurationFilePath 
# }

# Cleanup
# Remove-Item $configurationFilePath
