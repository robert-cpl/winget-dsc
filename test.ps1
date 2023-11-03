
using assembly System.Windows.Forms
using namespace System.Windows.Forms
using namespace System.Drawing

### Profile button names
$buttonNames = @("Developer", "Personal", "Tricent", "Custom")

### Top bar button settings
$topBarbuttonSize = [Size]::new(40, 42);

### Colors
$primaryColor = [Color]::FromArgb(255, 25, 25, 25)
$secondaryColor = [Color]::FromArgb(255, 33, 33, 33)
$accentColor = [Color]::FromArgb(255, 48, 48, 48)

$code = @"
[System.Runtime.InteropServices.DllImport("gdi32.dll")]
public static extern IntPtr CreateRoundRectRgn(int nLeftRect, int nTopRect,
    int nRightRect, int nBottomRect, int nWidthEllipse, int nHeightEllipse);
"@
$Win32Helpers = Add-Type -MemberDefinition $code -Name "Win32Helpers" -PassThru

$horizontalResolution = $(wmic PATH Win32_VideoController GET CurrentHorizontalResolution)[2].Trim()
$verticalResolution = $(wmic PATH Win32_VideoController GET CurrentVerticalResolution)[2].Trim()
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

# Add a icon to the top bar
$icon = [PictureBox] @{
    Image    = [Image]::FromFile("H:\repos\winget-dsc\visual-studio-code.png");
    SizeMode = [PictureBoxSizeMode]::StretchImage;
    Size     = [Size]::new(20, 20);
    Location = [Point]::new(10, 10);
}
$topBar.Controls.Add($icon)

# Add a title to the top bar
$title = [Label] @{
    Text      = "Winget DSC";
    ForeColor = [Color]::White;
    Font      = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
    Location  = [Point]::new(40, 12);
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
        
        # On click event that adds < symbol as a label to the right of the button and clears it from the other buttons
        $button.add_Click(({
                    $label = [Label] @{
                        Text      = "<";
                        ForeColor = [Color]::White;
                        Font      = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
                        Location  = [Point]::new($($button.Location.X + $button.Width + 5), $($button.Location.Y + 5));
                    }
                    $buttons | ForEach-Object {
                        # Remove any labels that contain < symbol
                        if ($_.Controls.Text -eq "<") {
                            echo "Removing label"
                            $_.Controls.RemoveAt(0)
                        }
                    }
                    $profileButtonArea.Controls.Add($label)
                }).GetNewClosure())

        

        $button.FlatAppearance.BorderSize = 0
        $button.FlatAppearance.BorderColor = $accentColor
        $buttons += $button
        $location.y += ($size.Height + 10 )
        $i++
    }
    $profileButtonArea.Controls.AddRange($buttons)
}

# Area that hold the profile buttons and lives underneath the top bar
$profileButtonArea = [Panel] @{
    BackColor = $primaryColor;
    Dock      = [DockStyle]::None;
    Location  = [Point]::new(0, 40);
    Size      = [Size]::new(140, $($form.Height - 80));
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
