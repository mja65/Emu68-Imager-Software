$WPF_LanguageSelectionWindow_OK_Button.Add_Click({
      
    $CheckBoxes = Get-Variable -name "WPF_LanguageSelectionWindow_*" | Where-Object { $_.Value -is [System.Windows.Controls.CheckBox] } | Select-Object -ExpandProperty Value
    
    $ExistingLanguages = $Script:GUIActions.Languages 
    $Script:GUIActions.Languages = [System.Collections.Generic.List[PSCustomObject]]::New()
    
    $languagesAdded = $false

    foreach ($Checkbox in $CheckBoxes) {
        $NametoCheck = ($CheckBox.Name) -replace "_checkbox"
        If ($Checkbox.IsChecked -eq $true){
            $Script:GUIActions.Languages.Add($NametoCheck)
            if ($Script:GuiActions.OSInstallMediaType -ne "CD" -and $existingLanguages -notcontains $NametoCheck) {
                $languagesAdded = $true
            }
        }
    }

    If ($languagesAdded -eq $true){
        $Script:GuiActions.FoundInstallMediatoUse = $null
        Update-UI -Emu68Settings
    }

    $null = $WPF_LanguageSelectionWindow.close()    


})