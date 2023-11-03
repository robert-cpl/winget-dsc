
using assembly System.Windows.Forms
using namespace System.Windows.Forms
using namespace System.Drawing

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
# Add label
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

# Add a button that acts as a dropdown menu with two choices
$dropdownMenu = [ContextMenuStrip]@{
    BackColor = $accentColor;
    ForeColor = [Color]::White;
}
$dropdownMenu.add_Paint({
        $hrgn = $Win32Helpers::CreateRoundRectRgn(0, 0, $dropdownMenu.Width, $dropdownMenu.Height, 10, 10)
        $dropdownMenu.Region = [Region]::FromHrgn($hrgn)
    })

# Add menu items to the ContextMenuStrip
$menuItem1 = [ToolStripMenuItem]@{
    Text      = "Developer"
    ForeColor = [Color]::White;
    BackColor = $accentColor;
    Size      = [Size]::new(70, 30);
}
$menuItem1.add_Click({ Write-Host "You selected Option 1" })
$dropdownMenu.Items.Add($menuItem1)

$menuItem2 = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItem2.Text = "Personal"
$menuItem2.add_Click({ Write-Host "You selected Option 2" })
$dropdownMenu.Items.Add($menuItem2)

# Create a new button
$profileOptionsDropdown = [Button] @{
    Text      = "Options";
    Font      = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
    ForeColor = [Color]::White;
    BackColor = $accentColor;
    FlatStyle = [FlatStyle]::Flat;
    Size      = [Size]::new(100, 30);
    Location  = [Point]::new(10, 50);
};

# add round corners to the button
$profileOptionsDropdown.add_Paint({
        $hrgn = $Win32Helpers::CreateRoundRectRgn(0, 0, $profileOptionsDropdown.Width, $profileOptionsDropdown.Height, 10, 10)
        $profileOptionsDropdown.Region = [Region]::FromHrgn($hrgn)
    })

$profileOptionsDropdown.FlatAppearance.BorderSize = 0
$profileOptionsDropdown.FlatAppearance.BorderColor = $accentColor

# Add a click event to the button that shows the dropdown menu
$profileOptionsDropdown.add_Click({
        $dropdownMenu.Show($profileOptionsDropdown, 0, $profileOptionsDropdown.Height)
    })

# Add the button to the form
$form.Controls.Add($profileOptionsDropdown)











$form.ShowDialog()
