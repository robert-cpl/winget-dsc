# Check for admin rights
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "WinGet needs Administrator rights to run. Restarting in Admin mode..."
    Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "iwr -useb https://raw.githubusercontent.com/robert-cpl/winget-dsc/main/run-configuration.ps1 | iex"
    break
}

Write-Host "See full source code on GitHub @ https://github.com/robert-cpl/winget-dsc" -ForegroundColor Yellow

# Check if running locally so we can use the local files
$runLocally = if (Test-Path ".gitignore") { $true } else { $false }

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
    if ($runLocally) {
        $fileName = Split-Path -Path $filePath -Leaf
        $filePath = ".\configuration\modules\$fileName"
    }
    $content = Invoke-WebRequest -useb $filePath

    # add indentation to each line
    $contentContent = $content.Content -replace '(?m)^', $indentation

    return $contentContent
}

$twoSpacesIndentation = '  '
$fourSpacesIndentation = '    '

$fileFolderPath = "https://raw.githubusercontent.com/robert-cpl/winget-dsc/main/configuration"
$headerContent = GetContent -filePath "$fileFolderPath/modules/header.yaml" -runLocally $runLocally
$footerContent = GetContent -filePath "$fileFolderPath/modules/footer.yaml" -indentation $twoSpacesIndentation -runLocally $runLocally

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
$headerContent, $sharedConfigContent, $configTypeContent, $footerContent | Set-Content -Path $configurationFilePath

# Run the configuration
winget configuration --file $configurationFilePath 

# Catch errors
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error running the configuration. See the error message above." -ForegroundColor Red
    Read-Host -Prompt "Press ENTER to exit."
    exit $LASTEXITCODE
}

Read-Host "Configuration completed. Press ENTER to exit."


[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$objForm = New-Object Windows.Forms.Form 

$horizontalResolution = $(wmic PATH Win32_VideoController GET CurrentHorizontalResolution)[2].Trim()
$verticalResolution = $(wmic PATH Win32_VideoController GET CurrentVerticalResolution)[2].Trim()

$objForm.Width = $horizontalResolution / 1.5
$objForm.Height = $verticalResolution / 1.5

$objForm.StartPosition = "CenterScreen"
$objForm.Text = "Desired State Configuration" 

[void] $objForm.ShowDialog() 