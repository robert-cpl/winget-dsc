
using assembly System.Windows.Forms
using namespace System.Windows.Forms
using namespace System.Drawing

# Get the scale factor of the primary screen
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class PInvoke {
    [DllImport("gdi32.dll")]
    public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
}
"@
$g = [System.Drawing.Graphics]::FromHwnd([System.IntPtr]::Zero)
$desktop = $g.GetHdc()
$LogicalScreenHeight = [PInvoke]::GetDeviceCaps($desktop, 10)
$PhysicalScreenHeight = [PInvoke]::GetDeviceCaps($desktop, 117)
$g.ReleaseHdc($desktop)
$g.Dispose()
$scaleFactor = $PhysicalScreenHeight / $LogicalScreenHeight


# Get the resolution and scale of the primary screen
$horizontalResolution = $(wmic PATH Win32_VideoController GET CurrentHorizontalResolution)[2].Trim() / $scaleFactor
$verticalResolution = $(wmic PATH Win32_VideoController GET CurrentVerticalResolution)[2].Trim() / $scaleFactor

### Profile button names
$buttonNames = @("CPL", "Developer", "Tricent", "Custom")

### Top bar button settings
$topBarbuttonSize = [Size]::new(40, 42);

### Colors
$primaryColor = [Color]::FromArgb(255, 25, 25, 25)
$secondaryColor = [Color]::FromArgb(255, 33, 33, 33)
$accentColor = [Color]::FromArgb(255, 48, 48, 48)
$buttonSelectedColor = [Color]::FromArgb(255, 165, 133, 3)

# Tooltip setup
$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.BackColor = $primaryColor
$toolTip.ForeColor = $buttonSelectedColor

$code = @"
[System.Runtime.InteropServices.DllImport("gdi32.dll")]
public static extern IntPtr CreateRoundRectRgn(int nLeftRect, int nTopRect,
    int nRightRect, int nBottomRect, int nWidthEllipse, int nHeightEllipse);
"@
$Win32Helpers = Add-Type -MemberDefinition $code -Name "Win32Helpers" -PassThru


$form = [Form] @{
    ClientSize      = [Point]::new($($horizontalResolution / 1.5), $($verticalResolution / 1.5));
    FormBorderStyle = [FormBorderStyle]::None;
    BackColor       = $primaryColor;
    Dock            = [DockStyle]::Fill;
    Text            = "Desired State Configuration";
    StartPosition   = "CenterScreen";
}

# Create a rounded corners
$form.add_Load({
        $hrgn = $Win32Helpers::CreateRoundRectRgn(0, 0, $form.Width, $form.Height, 15, 15)
        $form.Region = [Region]::FromHrgn($hrgn)
    })

### TOP BAR ###
$topBar = [Panel] @{
    BackColor = $secondaryColor;
    Dock      = [DockStyle]::Top;
    Height    = 40;
}
# Underline
$topBarUnderline = [Label] @{
    BorderStyle = [BorderStyle]::None;
    Height      = 1;
    BackColor   = $accentColor;
    Dock        = [DockStyle]::Bottom;
}
$topBar.Controls.Add($topBarUnderline);


# Add drag functionality to the top bar
$topBar.Add_MouseDown( { 
        $global:dragging = $true
        $global:mouseDragX = [System.Windows.Forms.Cursor]::Position.X - $form.Left
        $global:mouseDragY = [System.Windows.Forms.Cursor]::Position.Y - $form.Top
    })

# Move the form while the mouse is depressed (i.e. $global:dragging -eq $true)
$topBar.Add_MouseMove( { if ($global:dragging) {
            $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
            $currentX = [System.Windows.Forms.Cursor]::Position.X
            $currentY = [System.Windows.Forms.Cursor]::Position.Y
            [int]$newX = [Math]::Min($currentX - $global:mouseDragX, $screen.Right - $form.Width)
            [int]$newY = [Math]::Min($currentY - $global:mouseDragY, $screen.Bottom - $form.Height)
            $form.Location = New-Object System.Drawing.Point($newX, $newY)
        } })
$topBar.Add_MouseUp( { $global:dragging = $false })
$form.Controls.Add($topBar)

# Add a gear unicode to the top bar
$icon = [Label] @{
    Text      = [char]::ConvertFromUtf32(0x2699);
    ForeColor = [Color]::White;
    Font      = [Font]::new("Microsoft Sans Serif", 20, [FontStyle]::Bold);
    Location  = [Point]::new(6, 5);
    Size      = $topBarbuttonSize
}
$topBar.Controls.Add($icon)

# Add a title to the top bar
$title = [Label] @{
    Text      = "Winget DSC";
    ForeColor = [Color]::White;
    Font      = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
    Location  = [Point]::new(45, 12);
}
$topBar.Controls.Add($title)

# Create a close button with no border
$closeFormButton = [Button] @{
    Text      = "X";
    Font      = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
    ForeColor = [Color]::White;
    BackColor = $secondaryColor;
    FlatStyle = [FlatStyle]::Flat;
    Size      = $topBarbuttonSize
    Location  = [Point]::new($($form.Width - 40), 0);
}
$closeFormButton.add_Click({
        $form.Close()
    })
$closeFormButton.FlatAppearance.BorderSize = 0
$closeFormButton.FlatAppearance.BorderColor = $secondaryColor
$topBar.Controls.Add($closeFormButton)
# Add hover effect
$closeFormButton.add_MouseEnter({
        $closeFormButton.BackColor = [Color]::Red
    })
$closeFormButton.add_MouseLeave({
        $closeFormButton.BackColor = $secondaryColor
    })

# Create minimize button
$minimizeFormButton = [Button] @{
    Text      = "_";
    Font      = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
    ForeColor = [Color]::White;
    BackColor = $secondaryColor;
    FlatStyle = [FlatStyle]::Flat;
    Size      = $topBarbuttonSize
    Location  = [Point]::new($($form.Width - 80), 0);
};
$minimizeFormButton.add_Click({
        $form.WindowState = [FormWindowState]::Minimized
    })
$minimizeFormButton.FlatAppearance.BorderSize = 0
$minimizeFormButton.FlatAppearance.BorderColor = $secondaryColor
$topBar.Controls.Add($minimizeFormButton)

### PROFILE BUTTONS ###
# Function that takes a list of button names and creates a buttons
## Settings
$buttonRoundness = 5
$buttonSize = [Size]::new(100, 30)
$script:selectedButton = $null
function CreateProfileButtons($buttonNames) {
    $location = [Point]::new(10, 10)
    $size = $buttonSize
    $buttons = @()
    $profileLabel = [Label] @{
        Text      = "--- Profiles ---";
        ForeColor = $buttonSelectedColor;
        Font      = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
        Size      = $size;
        TextAlign = [ContentAlignment]::MiddleCenter;
        Location  = $location;
    }
    $buttons += $profileLabel
    $location.y += ($size.Height + 10 )

    $buttonNames | ForEach-Object -Begin { $i = 0 } -Process {
        $button = [Button] @{
            Text      = $buttonNames[$i];
            Font      = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
            ForeColor = [Color]::White;
            BackColor = $accentColor;
            FlatStyle = [FlatStyle]::Flat;
            Size      = $size;
            Location  = $location;
        };
        $button.add_Paint(({
                    $hrgn = $Win32Helpers::CreateRoundRectRgn(0, 0, $this.Width, $this.Height, $buttonRoundness, $buttonRoundness)
                    $this.Region = [Region]::FromHrgn($hrgn)
                }).GetNewClosure())
        
        # Change color to accent color on click and revert all other buttons to the primary color from profileButtonArea
        $button.add_Click({
                # If there's a previously selected button, revert its color
                if ($null -ne $script:selectedButton) {
                    $script:selectedButton.BackColor = $accentColor
                }

                # Change the BackColor of the clicked button and update the selected button
                $this.BackColor = $buttonSelectedColor
                $script:selectedButton = $this
            })
        
        # First button is selected by default
        if ($i -eq 0) {
            $button.BackColor = $buttonSelectedColor
            $script:selectedButton = $button
        }

        $button.FlatAppearance.BorderSize = 0
        $button.FlatAppearance.BorderColor = $accentColor
        $buttons += $button
        $location.y += ($size.Height + 10 )
        $i++
    }
    $profileButtonArea.Controls.AddRange($buttons)
}

# Area that holds the profile buttons and lives underneath the top bar
$profileButtonArea = [Panel] @{
    BackColor  = $primaryColor;
    Dock       = [DockStyle]::None;
    Location   = [Point]::new(0, 40);
    Size       = [Size]::new(120, $($form.Height - 100));
    AutoScroll = $true
}
$form.Controls.Add($profileButtonArea)

# Add 1 px right border to the profile button area
$profileButtonAreaBorder = [Label] @{
    BorderStyle = [BorderStyle]::None;
    Width       = 1;
    BackColor   = $accentColor;
    Dock        = [DockStyle]::Right;
}

$profileButtonArea.Controls.Add($profileButtonAreaBorder)

# Create the buttons
CreateProfileButtons($buttonNames)

### PACKAGES AREA ###
# Create a panel that will hold the content of the selected button
$buttonContentArea = [Panel] @{
    BackColor  = $secondaryColor;
    Dock       = [DockStyle]::Fill;
    Size       = [Size]::new($($form.Width - 120), $($form.Height - 160));
    AutoScroll = $true
}

$form.Controls.Add($buttonContentArea)

# Create a panel that will hold the content of the selected button
$buttonContentSearchBarArea = [Panel] @{
    BackColor = $primaryColor;
    Dock      = [DockStyle]::Bottom;
    Size      = [Size]::new($($form.Width), 60);
}

# Add top border to the buttonContentSearchBarArea
$buttonContentSearchBarAreaBorder = [Label] @{
    BorderStyle = [BorderStyle]::None;
    Height      = 1;
    BackColor   = $accentColor;
    Dock        = [DockStyle]::Top;
}
$buttonContentSearchBarArea.Controls.Add($buttonContentSearchBarAreaBorder)
$form.Controls.Add($buttonContentSearchBarArea)

# Function that takes a list of  names and create toggle square buttons and puts them in the buttonContentArea
function CreateToggleButtons($packages) {
    $toggleAreaTopMargin = 50
    $location = [Point]::new(130, $toggleAreaTopMargin)
    $size = [Size]::new(120, 40) 
    $columnWidth = $size.Width + 10

    $packages | ForEach-Object -Begin { $i = 0 } -Process {
        # If button name starts with ---, create a label instead
        if ($packages[$i].displayName -match "---") {
            $label = [Label] @{
                Text      = $packages[$i].displayName;
                ForeColor = $buttonSelectedColor;
                Font      = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
                Size      = $size;
                TextAlign = [ContentAlignment]::MiddleCenter;
                Location  = $location;
            }
            $buttonContentArea.Controls.Add($label)
        }
        else {
            $button = [Button] @{
                Text      = $packages[$i].displayName;
                Font      = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
                ForeColor = [Color]::White;
                BackColor = $accentColor;
                FlatStyle = [FlatStyle]::Flat;
                Size      = $size;
                Location  = $location;
            };
            # Add tooltip
            $toolTip.SetToolTip($button, $packages[$i].description)
            $button.add_Paint(({
                        $hrgn = $Win32Helpers::CreateRoundRectRgn(0, 0, $this.Width, $this.Height, $buttonRoundness, $buttonRoundness)
                        $this.Region = [Region]::FromHrgn($hrgn)
                    }).GetNewClosure())
            
            # Toggle color on click
            $button.add_Click({
                    if ($this.BackColor -eq $accentColor) {
                        $this.BackColor = $buttonSelectedColor
                    }
                    else {
                        $this.BackColor = $accentColor
                    }
                })
    
            $button.FlatAppearance.BorderSize = 0
            $button.FlatAppearance.BorderColor = $accentColor
            $buttonContentArea.Controls.Add($button)
        }


        # Check if the next button's location would exceed the height of the buttonContentArea
        if ($location.y + 2 * $size.Height -gt $buttonContentArea.Height) {
            # Start a new column
            $location.y = $toggleAreaTopMargin
            $location.x += $columnWidth
        }
        else {
            # Continue in the current column
            $location.y += $size.Height + 10
        }

        $i++
    }
}

# Load packages.json file
$packages = Get-Content -Raw -Path "packages.json" | ConvertFrom-Json
CreateToggleButtons($packages)

#### SEARCH BAR ####
$searchBarSearchText = "search"
# Add centered search bar to the buttonContentSearchBarArea
$searchBarPanel = [Panel] @{
    BackColor = $secondaryColor;
    Location  = [Point]::new(($buttonContentSearchBarArea.Width / 2) - 100, 10);
    Size      = [Size]::new(300, 40);
}
# Add Reset all selections button right next to the search bar
$resetSelectionsButton = [Button] @{
    Text      = [char]::ConvertFromUtf32(0x00002611);
    Font      = [Font]::new("Microsoft Sans Serif", 20, [FontStyle]::Bold);
    ForeColor = $buttonSelectedColor;
    BackColor = $secondaryColor;
    FlatStyle = [FlatStyle]::Flat;
    Size      = [Size]::new(40, 40);
    Location  = [Point]::new(($buttonContentSearchBarArea.Width / 2) + 210, 10);
    
};
$toolTip.SetToolTip($resetSelectionsButton, "Reset all selections `n (Ctrl + R)")
$resetSelectionsButton.FlatAppearance.BorderSize = 0
$resetSelectionsButton.FlatAppearance.BorderColor = $secondaryColor

$resetSelectionsButton.add_Paint(({
            $hrgn = $Win32Helpers::CreateRoundRectRgn(0, 0, $this.Width, $this.Height, $buttonRoundness, $buttonRoundness)
            $this.Region = [Region]::FromHrgn($hrgn)
        }).GetNewClosure())
$resetSelectionsButton.add_Click({
        $allButtons = $buttonContentArea.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }
        foreach ($button in $allButtons) {
            $button.BackColor = $accentColor
        }
    })
$buttonContentSearchBarArea.Controls.Add($resetSelectionsButton)

# Round corners
$searchBarPanel.add_Paint(({
            $hrgn = $Win32Helpers::CreateRoundRectRgn(0, 0, $this.Width, $this.Height, $buttonRoundness, $buttonRoundness)
            $this.Region = [Region]::FromHrgn($hrgn)
        }).GetNewClosure())

$searchBar = [TextBox] @{
    Text        = $searchBarSearchText;
    ForeColor   = [Color]::Gray;
    BackColor   = $secondaryColor;
    Font        = [Font]::new("Microsoft Sans Serif", 24, [FontStyle]::Bold);
    Size        = [Size]::new(300, 40);
    BorderStyle = [BorderStyle]::None;
    TextAlign   = [HorizontalAlignment]::Center;
}
$searchBar.add_GotFocus({
        if ($searchBar.Text -eq $searchBarSearchText) {
            $searchBar.Text = ""
        }
    })
$searchBar.add_LostFocus({
        if ($searchBar.Text -eq "") {
            $searchBar.Text = $searchBarSearchText
        }
    })

# add select all text in the search bar with ctrl+a
$searchBar.add_KeyDown({
        if ($_.KeyCode -eq "A" -and $_.Control) {
            $searchBar.SelectAll()
            $_.SuppressKeyPress = $true
        }
    })

# On Enter perform click on all visible buttons
$searchBar.add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            $allButtons = $buttonContentArea.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }
            $visibleButtons = $allButtons | Where-Object { $_.Visible -eq $true }
            foreach ($button in $visibleButtons) {
                $button.PerformClick()
            }
            # Remove Windows ding sound
            $_.SuppressKeyPress = $true
        }
    })

$searchBarPanel.Controls.Add($searchBar)
$buttonContentSearchBarArea.Controls.Add($searchBarPanel)

# Store the original locations of the buttons
$originalLocations = @{}
$buttonContentArea.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] } | ForEach-Object { $originalLocations[$_.Text] = $_.Location }

$searchBar.add_TextChanged({
        $searchText = $searchBar.Text
        $buttonlocation = [Point]::new(130, $toggleAreaTopMargin)
        $allButtons = $buttonContentArea.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }
        if ($searchText -eq "" -or $searchText -eq $searchBarSearchText) {
            # Reset all buttons to their original locations and make them visible
            foreach ($button in $allButtons) {
                $button.Location = $originalLocations[$button.Text]
                $button.Visible = $true
            }
        }
        else {
            # Update the location of matching buttons and hide non-matching buttons
            $matchingButtons = $allButtons | Where-Object { $_.Text -like "*$searchText*" }
            $nonMatchingButtons = $allButtons | Where-Object { $_.Text -notlike "*$searchText*" }
            foreach ($button in $matchingButtons) {
                $buttonlocation.y += $button.Height + 10
                $button.Location = $buttonlocation
                $button.Visible = $true
                $toggleAreaTopMargin += $button.Height + 50
            }
            foreach ($button in $nonMatchingButtons) {
                $button.Visible = $false
            }
        }
    })

$form.ShowDialog()
