function Show-DecisionBox {
    param (
        $Msg_Body,
        $Msg_Header
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Msg_Header
    $form.Size = New-Object System.Drawing.Size(350, 200)
    $form.StartPosition = 'CenterScreen'
    
    # --- UI Customization ---
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ControlBox = $false # Hides X and menu
    
    # --- Add Text (Label) ---
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Msg_Body
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(300, 80)
    $form.Controls.Add($label)
    
    # --- Buttons ---
    $btnYes = New-Object System.Windows.Forms.Button
    $btnYes.Text = "Yes"
    $btnYes.Location = New-Object System.Drawing.Point(20, 120)
    $btnYes.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $form.Controls.Add($btnYes)
    
    $btnNo = New-Object System.Windows.Forms.Button
    $btnNo.Text = "No"
    $btnNo.Location = New-Object System.Drawing.Point(110, 120)
    $btnNo.DialogResult = [System.Windows.Forms.DialogResult]::No
    $form.Controls.Add($btnNo)
    
    $btnNever = New-Object System.Windows.Forms.Button
    $btnNever.Text = "Never Again"
    $btnNever.Location = New-Object System.Drawing.Point(200, 120)
    $btnNever.DialogResult = [System.Windows.Forms.DialogResult]::Ignore
    $form.Controls.Add($btnNever)
    
    # Show and capture
    $result = $form.ShowDialog()
    
    # Cleanup memory
    $form.Dispose()
    
    switch ($result) {
    "Yes"    {return $result }
    "No"     { return $result }
    "Ignore" { return "Never"}

    }
        
}