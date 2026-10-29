$WPF_P96Resolutions_Add_Custom_Resolution_Button.Add_Click({
    $rawWidth = $WPF_P96Resolutions_Input_Width.Text.Trim()
    $rawHeight = $WPF_P96Resolutions_Input_Height.Text.Trim()
    
    $width = 0; $height = 0
    
    # 1. Type validation: ensure inputs are valid whole numbers
    if (-not [int]::TryParse($rawWidth, [ref]$width) -or -not [int]::TryParse($rawHeight, [ref]$height)) {
        $MessageHeader = "Validation Error"
        $MessageBody = "Width and Height must be valid whole numbers."
        $null = Show-WarningorError -Msg_Header $MessageHeader -Msg_Body $MessageBody -BoxTypeError -ButtonType_OK
        return
    }

    # 2. Positive value check
    if ($width -le 0 -or $height -le 0) {
        $MessageHeader = "Invalid Resolution"
        $MessageBody = "Width and Height must be greater than zero."
        $null = Show-WarningorError -Msg_Header $MessageHeader -Msg_Body $MessageBody -BoxTypeError -ButtonType_OK
        return
    }
      

    # 3. Sanity range limits (Min 320x200, Max 8192x8192)
    if ($width -lt 320 -or $height -lt 200) {
        $MessageHeader = "Invalid Resolution"
        $MessageBody = "Resolution is too small. Minimum supported resolution is 320x200."
        $null = Show-WarningorError -Msg_Header $MessageHeader -Msg_Body $MessageBody -BoxTypeError -ButtonType_OK
        return
    }
     

    if ($width -gt 8192 -or $height -gt 8192) {
        $MessageHeader = "Invalid Resolution"
        $MessageBody = "Resolution is too large. Maximum supported resolution is 8192x8192."
        $null = Show-WarningorError -Msg_Header $MessageHeader -Msg_Body $MessageBody -BoxTypeError -ButtonType_OK
        return
    }
     

    $resValue = "${width}x${height}"
 
    # 4. Check against Available Presets CSV
    $P96Resolutions = Get-InputFileCSV -CSV "P96Resolutions"
    if ($P96Resolutions | Where-Object { ($width -eq $_.Horizontal -and $height -eq $_.Vertical) }) {
        $MessageHeader = "Preset Exists"
        $MessageBody = "This resolution already exists in the Available Presets. Please select it from the preset list instead."
        $null = Show-WarningorError -Msg_Header $MessageHeader -Msg_Body $MessageBody -BoxTypeError -ButtonType_OK
        return
    }
        
    # 5. Check against target list duplicates
    if ($TargetResolutions | Where-Object { $_.Value -eq $resValue }) {
        $MessageHeader = "Duplicate Warning"
        $MessageBody = "This resolution is already included in the target list."
        $null = Show-WarningorError -Msg_Header $MessageHeader -Msg_Body $MessageBody -BoxTypeError -ButtonType_OK
        return
    }

    # Add as tagged Custom entry
    $newItem = [PSCustomObject]@{
        Value    = $resValue
        IsCustom = $true
        Display  = "$resValue [Custom]"
    }
    
    $TargetResolutions.Add($newItem)
    $WPF_P96Resolutions_IncludedResolutionsList.SelectedItem = $newItem
})

