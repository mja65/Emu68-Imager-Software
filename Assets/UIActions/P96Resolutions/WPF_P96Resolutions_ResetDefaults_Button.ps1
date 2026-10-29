$WPF_P96Resolutions_ResetDefaults_Button.Add_Click({

    $DefaultP96Resolutions = Get-InputFileCSV -CSV "P96Resolutions"
    $P96Resolutions = @($DefaultP96Resolutions; $selectedWBModeP96) | Where-Object { $_ -ne $null } | Group-Object value | ForEach-Object { $_.Group[0] }
    $selectedWBMode = $Script:GUIActions.AvailableScreenModesWB | Where-Object { $_.FriendlyName -eq $Script:GUIActions.ScreenModetoUseWB }
    $selectedWBModeP96 = if ($selectedWBMode) { $DefaultP96Resolutions | Where-Object { $_.value -eq $selectedWBMode.value } } else { $null }

    $TargetResolutions.Clear()
    $AvailableResolutions.Clear()

    foreach ($Resolution in $P96Resolutions) { 
        $Display = if ($Resolution.value -eq $SelectedWBMode.value) { "$($Resolution.Display) [SelectedWBMode]" } else { $Resolution.Display }
        If ($Resolution.Selected -eq $true){
            $ItemObject = [PSCustomObject]@{
                Value = $Resolution.Value
                IsCustom = $false
                Display = $Display
            }
            $TargetResolutions.Add($ItemObject)
                        }
        else {
            $ItemObject = [PSCustomObject]@{
                Value = $Resolution.Value
                IsCustom = $false
                Display = $Display
            }

            $AvailableResolutions.Add($ItemObject)
        }
    }

})