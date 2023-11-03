
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
$buttonNames = @("Developer", "CPL", "Tricent", "Custom")

### Top bar button settings
$topBarbuttonSize = [Size]::new(40, 42);

### Colors
$primaryColor = [Color]::FromArgb(255, 25, 25, 25)
$secondaryColor = [Color]::FromArgb(255, 33, 33, 33)
$accentColor = [Color]::FromArgb(255, 48, 48, 48)
$buttonSelectedColor = [Color]::FromArgb(255, 165, 133, 3)

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

# Top bar 
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

# Bottom bar
$bottomBar = [Panel] @{
    BackColor = $secondaryColor;
    Dock      = [DockStyle]::Bottom;
    Height    = 40;
}
# Underline
$bottomBarUnderline = [Label] @{
    BorderStyle = [BorderStyle]::None;
    Height      = 1;
    BackColor   = $accentColor;
    Dock        = [DockStyle]::Top;
}
$bottomBar.Controls.Add($bottomBarUnderline);
$form.Controls.Add($bottomBar)

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

# Function that takes a list of button names and creates a buttons
## Settings
$buttonRoundness = 3
$buttonSize = [Size]::new(100, 30)
$script:selectedButton = $null
function CreateProfileButtons($buttonNames) {
    $location = [Point]::new(10, 10)
    $size = $buttonSize
    $buttons = @()
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
    BackColor = $primaryColor;
    Dock      = [DockStyle]::None;
    Location  = [Point]::new(0, 40);
    Size      = [Size]::new(120, $($form.Height - 80));
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




$form.ShowDialog()
