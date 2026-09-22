Get-InputFileCSV -CSV "Emu68Versions" | ForEach-Object {
    $WPF_StartPage_Emu68Version_Dropdown.AddChild($_.Emu68VersionTypeFriendlyName)
    if ($_.Default -eq $true){
        $Script:GUIActions.Emu68VersionType = $_.Emu68VersionType
    }
}

#$WPF_StartPage_NetworkStack_Dropdown.Items.Clear()

Get-InputFileCSV -CSV "NetworkStackVersions" | ForEach-Object {
    If ($_.IncludeforUserSelection -eq $true -and $Script:GUIActions.Emu68VersionType -in @($_.Emu68VersionType -split ',')){
        $WPF_StartPage_NetworkStack_Dropdown.AddChild($_.NetworkStackFriendlyName)
        if ($_.Default -eq $true){
            $Script:GUIActions.NetworkStack = $_.NetworkStack
        }
    }
}
 
$WPF_StartPage_Emu68Version_Dropdown.Add_SelectionChanged({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }

    Get-InputFileCSV -CSV "Emu68Versions" | ForEach-Object {
        if ($WPF_StartPage_Emu68Version_Dropdown.SelectedItem -eq $_.Emu68VersionTypeFriendlyName){
            $Script:GUIActions.Emu68VersionType = $_.Emu68VersionType
            $AllowC790 = ((Get-InputFileCSV -CSV "Emu68Versions").where({ $_.Emu68VersionType -eq $Script:GUIActions.Emu68VersionType })).AllowC790
            If (($AllowC790 -ne $true) -and ($Script:GUIActions.UnicamDeviceType -eq "c790")){
                $Script:GUIActions.UnicamEnabled = $false    
                $Script:GUIActions.UnicamDeviceType = $null   
                $Script:GUIActions.UnicamStartonBoot = [bool]$null
                $Script:GUIActions.UnicamScalingType = $null
                $Script:GUIActions.UnicamBParameter = $null
                $Script:GUIActions.UnicamCParameter = $null
                $Script:GUIActions.UnicamPhase = $null
                $Script:GUIActions.UnicamAspectRatio = $null
                $Script:GUIActions.UnicamScanLinesNonLaced = $null
                $Script:GUIActions.UnicamScanLinesLaced = $null    
                $Script:GUIActions.UnicamSizeX = $null
                $Script:GUIActions.UnicamSizeY = $null
                $Script:GUIActions.UnicamOffsetX = $null
                $Script:GUIActions.UnicamOffsetY = $null   
            } 

            If ($_.EnableBupTest -eq $false){
                $Script:GUIActions.EnableBupTest = $false
            }
            If ($Script:GUIActions.MUIVersion -notin ($_.MUIVersion -split ',')){
                $Script:GUIActions.MUIVersion = $_.MUIVersionDefault
            }
            If ($Script:GUIActions.PoseidonVersion -notin ($_.PoseidonVersion -split ',')){
                $Script:GUIActions.PoseidonVersion = $_.PoseidonVersionDefault
                if ($Script:GUIActions.PoseidonVersion){
                    $Script:GUIActions.EnableUSBStack = $true
                }
                else {
                    $Script:GUIActions.EnableUSBStack = $false
                }

            }
            If ($Script:GUIActions.NetworkStack -notin ($_.PoseidonVersion -split ',')){
                $Script:GUIActions.NetworkStack = $_.NetworkStackDefault                
            }

            if ($_.Default -eq $true){
                $Script:GUIActions.SCSIDeviceDisabled = $null
                $Script:GUIActions.DMAEnabled = $null
                $Script:GUIActions.IRQEnabled = $null
                $Script:GUIActions.AgnusType = $null
                $Script:GUIActions.SDLowSpeed = $true
                $Script:GUIActions.SDOverClock = $false
                $Script:GUIActions.EnableUSBStack = $false   
                $Script:GUIActions.PoseidonVersion = $null                  
            }
            else {
                $Msg_Header ='Alpha or Beta Emu68!'   
                $Msg_Body = "You have selected a Emu68 version that is an Alpha or Beta. This may not be as stable as a released version"
                $null = Show-WarningorError -Msg_Body $Msg_Body -Msg_Header $Msg_Header -BoxTypeNone -ButtonType_OK
                $Script:GUIActions.SCSIDeviceDisabled = $false
                $Script:GUIActions.DMAEnabled = $false
                $Script:GUIActions.IRQEnabled = $false
                $Script:GUIActions.AgnusType = $null
                $Script:GUIActions.SDLowSpeed = $true
                $Script:GUIActions.SDOverClock = $false                   
            }
        }
    }
    
    $WPF_StartPage_NetworkStack_Dropdown.Items.Clear()
    
    Get-InputFileCSV -CSV "NetworkStackVersions"| Where-Object { $_.IncludeforUserSelection -eq $true } | ForEach-Object {
        If ($Script:GUIActions.Emu68VersionType -in @($_.Emu68VersionType -split ',')){
            $WPF_StartPage_NetworkStack_Dropdown.AddChild($_.NetworkStackFriendlyName)
            if ($_.Default -eq $true){
                $Script:GUIActions.NetworkStack = $_.NetworkStack
            }
        }
    }
    
    update-ui -Emu68Settings
})