$WPF_StartPage_P96Resolutions_Button.Add_Click({

    Remove-Variable -Name 'WPF_P96Resolutions_*' 
    $WPF_P96ResolutionsWindow = Get-XAML -WPFPrefix 'WPF_P96Resolutions_' -XMLFile '.\Assets\WPF\Window_P96Resolutions.xaml'  -ActionsPath '.\Assets\UIActions\P96Resolutions\' -AddWPFVariables
    
    $DefaultP96Resolutions = Get-InputFileCSV -CSV "P96Resolutions"
    
    $selectedWBMode = $Script:GUIActions.AvailableScreenModesWB | Where-Object { $_.FriendlyName -eq $Script:GUIActions.ScreenModetoUseWB }
    $selectedWBModeP96 = if ($selectedWBMode) { $DefaultP96Resolutions | Where-Object { $_.value -eq $selectedWBMode.value } } else { $null }

    $AvailableResolutions = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()
    $TargetResolutions = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()
    
    if ($Script:GUIActions.SelectedP96Resolutions) {
        $AvailableResolutionstoInclude = $DefaultP96Resolutions.Where({ $_.value -notin $Script:GUIActions.SelectedP96Resolutions })
        $TargetResolutionstoInclude = $Script:GUIActions.SelectedP96Resolutions
        foreach ($Resolution in $DefaultP96Resolutions) { 
            If ($Resolution.Value -in $AvailableResolutionstoInclude.value){
                $AvailableResolutions.Add([PSCustomObject]@{
                    Value = $Resolution.Value
                    IsCustom = $false
                    Display = $Resolution.Display                                  
                })
            }
            elseif ($Resolution.Value -in $TargetResolutionstoInclude){
                $TargetResolutions.Add([PSCustomObject]@{
                    Value = $Resolution.Value
                    IsCustom = $false
                    Display = if ($Resolution.value -eq $SelectedWBMode.value) { "$($Resolution.Display) [SelectedWBMode]" } else { $Resolution.Display }                                    
                })
            }

        }
    }
    else {
        $AvailableResolutionstoInclude = @($DefaultP96Resolutions; $selectedWBModeP96) | 
        Where-Object { $_ -ne $null } | 
        Group-Object value | 
        ForEach-Object { $_.Group[0] }
        
        foreach ($Resolution in $AvailableResolutionstoInclude) { 
            $Display = if ($Resolution.value -eq $SelectedWBMode.value) { "$($Resolution.Display) [SelectedWBMode]" } else { $Resolution.Display }
            If ($Resolution.Selected -eq $true){
                $TargetResolutions.Add([PSCustomObject]@{
                    Value = $Resolution.Value
                    IsCustom = $false
                    Display = $Display
                })
            }
            else {
                $AvailableResolutions.Add([PSCustomObject]@{
                    Value = $Resolution.Value
                    IsCustom = $false
                    Display = $Display
                })
            }
        }
    }
    

    $WPF_P96Resolutions_AvailableResolutionsList.ItemsSource = $AvailableResolutions
    $WPF_P96Resolutions_IncludedResolutionsList.ItemsSource = $TargetResolutions

    $WPF_P96ResolutionsWindow.ShowDialog() | out-null
     

    $WPF_P96ResolutionsWindow.close()

})

