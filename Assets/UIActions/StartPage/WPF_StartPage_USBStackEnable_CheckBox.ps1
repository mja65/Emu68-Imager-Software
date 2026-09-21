$WPF_StartPage_USBStackEnable_CheckBox.add_Checked({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }   
    $Script:GUIActions.EnableUSBStack = $true
    Get-InputFileCSV -CSV "Emu68Versions" | ForEach-Object {
        if ($Script:GUIActions.Emu68VersionType -eq $_.Emu68VersionType){
            $Script:GUIActions.PoseidonVersion = $_.PoseidonVersionDefault
        } 
    }
    Update-UI -Emu68Settings
})

$WPF_StartPage_USBStackEnable_CheckBox.add_Unchecked({
    $Script:GUIActions.EnableUSBStack = $false
    $Script:GUIActions.PoseidonVersion = $null
    Update-UI -Emu68Settings
})   

Get-InputFileCSV -CSV "PoseidonVersions" | ForEach-Object {
    if ($_.Default -eq $true){
        $Script:GUIActions.PoseidonVersion = $_.PoseidonVersionVersion
        If ($Script:GUIActions.PoseidonVersion) {
            $Script:GUIActions.EnableUSBStack = $true
        }
        else {
            $Script:GUIActions.EnableUSBStack = $false            
        }
    }
}