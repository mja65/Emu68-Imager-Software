$Script:GUIActions.AvailableKickstarts =  (Get-InputFileCSV -CSV 'OSVersionsToInstall') | Select-Object 'KickstartVersion','KickstartVersionFriendlyName','InstallMedia'

foreach ($Kickstart in $Script:GUIActions.AvailableKickstarts) {
    $WPF_StartPage_KickstartVersion_Dropdown.AddChild(($Kickstart.KickstartVersionFriendlyName).tostring())
}

 $WPF_StartPage_KickstartVersion_Dropdown.Add_SelectionChanged({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }
     foreach ($Kickstart in $Script:GUIActions.AvailableKickstarts) {
         if ($Kickstart.KickstartVersionFriendlyName -eq $WPF_StartPage_KickstartVersion_Dropdown.SelectedItem){
             if ($Kickstart.KickstartVersion -ne $Script:GUIActions.KickstartVersiontoUse){
                 $Script:GUIActions.KickstartVersiontoUse = $Kickstart.KickstartVersion 
                 $Script:GUIActions.DefaultPackagesSelected = $true
                 $Script:GUIActions.DefaultIconsetSelected = $true
                 $Script:GUIActions.SelectedIconSet = $null
                 $Script:GUIActions.KickstartVersiontoUseFriendlyName = $WPF_StartPage_KickstartVersion_Dropdown.SelectedItem
                 $Script:GUIActions.OSInstallMediaType = $Kickstart.InstallMedia
                 $Script:GUIActions.FoundInstallMediatoUse = $null
                 $Script:GUIActions.FoundKickstarttoUse = $null
                 If ($Script:GUIActions.PoseidonVersion) {
                     If (-not ([system.version]$($Script:GUIActions.KickstartVersiontoUse.major) -eq 3) -and ([system.version]$($Script:GUIActions.KickstartVersiontoUse.minor) -eq 2)){
                        If ($Script:GUIActions.EnableUSBStack -eq $true){
                            $Script:GUIActions.PoseidonVersion = "4.x"
                        }
                        else {
                            $Script:GUIActions.PoseidonVersion = $null                            
                        }
                     }
                 }
              #   $Script:GUIActions.ROMLocation = $null
              #   $Script:GUIActions.InstallMediaLocation = $null
                 $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = "TRUE"
                 Write-AvailableIconsets
                 update-ui -Emu68Settings
             }
             break
         }
     }

})

