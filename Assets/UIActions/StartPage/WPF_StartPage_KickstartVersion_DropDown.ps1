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

                if ($Script:GUIActions.KickstartVersiontoUse -ne '3.2.3') {
                    $Script:GUIActions.CreateCustomKickstart = $false
                }

                If (-not ($Script:GUIActions.Languages.Count -eq 1 -and @($Script:GUIActions.Languages) -eq "English")){
                    $OSandPackageLanguages = ((@(Get-InputFileCSV -CSV "OSLanguages").Language) + (@(Get-InputFileCSV -CSV "PackageLanguages").Language)) | Sort-Object -Unique
                    $ExistingLanguages = $Script:GUIActions.Languages 
                    $Script:GUIActions.Languages = [System.Collections.Generic.List[PSCustomObject]]::New()
                    foreach ($Language in $ExistingLanguages) {
                        If ($Language -eq "English" -or $Language -in $OSandPackageLanguages){
                            $Script:GUIActions.Languages.Add($Language) 
                        }
                    }
                }

                $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = "TRUE"

                $WPF_StartPage_IconSet_DropDown.ItemsSource = $null
                $AvailableIconsSet = @(Get-InputFileCSV -CSV "IconSets")
                foreach ($item in $AvailableIconsSet) {
                    $WPF_StartPage_IconSet_DropDown.AddChild($item.IconSet)
                    if ($item.IconsDefaultInstall -eq $true) {
                        $Script:GUIActions.SelectedIconSet = $item.IconSet
                    }
                }
   
                update-ui -Emu68Settings
            }
            break
        }
    }
})

