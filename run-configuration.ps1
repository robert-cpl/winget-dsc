# Check for admin rights
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "WinGet needs Administrator rights to run. Restarting in Admin mode..."
    Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "iwr -useb https://raw.githubusercontent.com/robert-cpl/winget-dsc/main/run-configuration.ps1 | iex"
    break
}

# Local development variables
$isLocalDevelopment = $false

# User Input
function GetUserInput {
    param(
        [string]$message,
        [string[]]$choices,
        [string]$defaultValue
    )

    while ($true) {
        # User input
        Write-Host "$message Press ENTER for default value ($defaultValue)." -ForegroundColor Green
        $userInput = Read-Host

        # Validation
        $userInput = $userInput.ToLower()
        if ($userInput -eq "") {
            return $defaultValue
        }

        if ($choices -notcontains $userInput) {
            Write-Host "Invalid input, try again." -ForegroundColor Yellow
            continue
        }
        break
    }
    return $userInput
}

$dscType = GetUserInput -message "What DSC configuration you want to use? (personal/work)." -choices ["personal", "work"] -defaultValue "personal"

# Configuration file path setup
$configurationFolderPath = "./configurations"
if (!(Test-Path $configurationFolderPath)) {
    echo "Creating configuration folder to path $configurationFolderPath."
    New-Item -ItemType Directory -Path $configurationFolderPath
}

$configurationFileName = "configuration.dsc.yaml"
$configurationFilePath = "$configurationFolderPath/$configurationFileName"

# Modules
$fileFolderPath = if ($isLocalDevelopment) {"./configurations"} else {"https://raw.githubusercontent.com/robert-cpl/winget-dsc/main/configurations"}
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

winget configuration --file $configurationFilePath 

#Cleanup
Remove-Item $configurationFilePath
