# Check for admin rights
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "WinGet needs Administrator rights to run. Restarting in Admin mode..."
    Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "iwr -useb https://raw.githubusercontent.com/robert-cpl/winget-dsc/main/run-configuration.ps1 | iex"
    break
}

Write-Host "See full source code on GitHub @ https://github.com/robert-cpl/winget-dsc" -ForegroundColor Yellow

# Check if running locally so we can use the local files
$runLocally = $false

# Functions
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

# Variables
$defaultDscProfile = "personal"
$dscProfiles = @("personal", "developer")

# User Input

$dscProfile = GetUserInput -message "What DSC profile you want to install? ($($dscProfiles -join '/' ))." -choices $dscProfiles -defaultValue $defaultDscProfile

# Configuration file path setup
$desktopPath = $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$configurationFolderPath = "$($DesktopPath)\winget-configuration"
if (!(Test-Path $configurationFolderPath)) {
    Write-Host "Creating missing configuration folder."
    $folder = New-Item -ItemType Directory -Path $configurationFolderPath
    $folderPath = $folder.FullName
    Write-Host "Configuration folder created at $folderPath."
}

$configurationFileName = "configuration.dsc.yaml"
$configurationFilePath = "$configurationFolderPath/$configurationFileName"

# Modules
function GetContent(){
    param(
        [string]$filePath,
        [string]$indentation = '',
        [bool]$runLocally = $true
    )
    Write-Host $filePath
    $content = if ($runLocally) {Get-Content $filePath}else{(Invoke-WebRequest -useb $filePath).Content}

    # add indentation to each line
    $formatedContent = $content -replace '(?m)^', $indentation

    return $formatedContent
}

$twoSpacesIndentation = '  '
$fourSpacesIndentation = '    '

$fileFolderPath = if($runLocally){"./configuration"}else{"https://raw.githubusercontent.com/robert-cpl/winget-dsc/main/configuration"}
$headerContent = GetContent -filePath "$fileFolderPath/modules/header.yaml" -runLocally $runLocally
$footerContent = GetContent -filePath "$fileFolderPath/modules/footer.yaml" -indentation $twoSpacesIndentation -runLocally $runLocally
$finishersContent = GetContent -filePath "$fileFolderPath/modules/finishers.yaml" -indentation $fourSpacesIndentation -runLocally $runLocally

# DSC's
$sharedConfigContent = GetContent -filePath "$fileFolderPath/shared.yaml" -indentation $fourSpacesIndentation -runLocally $runLocally
$personalConfigContent = GetContent -filePath "$fileFolderPath/personal.yaml" -indentation $fourSpacesIndentation -runLocally $runLocally
$developerConfigContent = GetContent -filePath "$fileFolderPath/developer.yaml" -indentation $fourSpacesIndentation -runLocally $runLocally

if ($dscProfile -eq $defaultDscProfile) {
    Write-Host "Using $dscProfile DSC configuration." -ForegroundColor Yellow
    $configTypeContent = $personalConfigContent
} else{
    Write-Host "Using $dscProfile DSC configuration." -ForegroundColor Yellow
    $configTypeContent = $developerConfigContent
}

# Build the DSC configuration file
$headerContent, $sharedConfigContent, $configTypeContent, $finishersContent, $footerContent | Set-Content -Path $configurationFilePath

# Run the configuration
winget configuration --file $configurationFilePath 

# Catch errors
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error running the configuration. See the error message above." -ForegroundColor Red
    Read-Host -Prompt "Press ENTER to exit."
    exit $LASTEXITCODE
}

Read-Host "Configuration completed. Press ENTER to exit."
