
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$code = @"
[System.Runtime.InteropServices.DllImport("gdi32.dll")]
public static extern IntPtr CreateRoundRectRgn(int nLeftRect, int nTopRect,
    int nRightRect, int nBottomRect, int nWidthEllipse, int nHeightEllipse);
"@
$Win32Helpers = Add-Type -MemberDefinition $code -Name "Win32Helpers" -PassThru

$horizontalResolution = $(wmic PATH Win32_VideoController GET CurrentHorizontalResolution)[2].Trim()
$verticalResolution = $(wmic PATH Win32_VideoController GET CurrentVerticalResolution)[2].Trim()
$form = [Form] @{
    ClientSize = [Point]::new($($horizontalResolution / 1.5),$($verticalResolution / 1.5));
    FormBorderStyle = [FormBorderStyle]::None;
    BackColor = [SystemColors]::ControlLight;
    Dock = [DockStyle]::Fill;
    Text = "Desired State Configuration";
    StartPosition = "CenterScreen";
}

# Create a rounded corners
$form.add_Load({
    $hrgn = $Win32Helpers::CreateRoundRectRgn(0,0,$form.Width, $form.Height, 15,15)
    $form.Region = [Region]::FromHrgn($hrgn)
})

$lblTitle = [Label] @{
    Text = "Desired State Configuration";
    Font = [Font]::new("Microsoft Sans Serif", 20, [FontStyle]::Bold);
    ForeColor = [SystemColors]::ControlDarkDark;
    AutoSize = $true;
    Location = [Point]::new(10,10);
}
$form.Controls.Add($lblTitle)

# Create a close button
$closeFormButton = [Button] @{
        Text = "X";
        Font = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
        ForeColor = [SystemColors]::ControlDarkDark;
        BackColor = [SystemColors]::ControlLight;
        FlatStyle = [FlatStyle]::Flat;
        Size = [Size]::new(30,30);
        Location = [Point]::new($($form.Width - 40), 10);
    };
$closeFormButton.add_Click({
    $form.Close()
})
$form.Controls.Add($closeFormButton)

# Create minimize button
$minimizeFormButton = [Button] @{
        Text = "-";
        Font = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
        ForeColor = [SystemColors]::ControlDarkDark;
        BackColor = [SystemColors]::ControlLight;
        FlatStyle = [FlatStyle]::Flat;
        Size = [Size]::new(30,30);
        Location = [Point]::new($($form.Width - 80), 10);
    };
$minimizeFormButton.add_Click({
    $form.WindowState = [FormWindowState]::Minimized
})
$form.Controls.Add($minimizeFormButton)

# Create maximize button
$maximizeFormButton = [Button] @{
        Text = "+";
        Font = [Font]::new("Microsoft Sans Serif", 10, [FontStyle]::Bold);
        ForeColor = [SystemColors]::ControlDarkDark;
        BackColor = [SystemColors]::ControlLight;
        FlatStyle = [FlatStyle]::Flat;
        Size = [Size]::new(30,30);
        Location = [Point]::new($($form.Width - 120), 10);
    };
$maximizeFormButton.add_Click({
    if ($form.WindowState -eq [FormWindowState]::Normal) {
        $form.WindowState = [FormWindowState]::Maximized
    } else {
        $form.WindowState = [FormWindowState]::Normal
    }
})
$form.Controls.Add($maximizeFormButton)




$form.ShowDialog()
