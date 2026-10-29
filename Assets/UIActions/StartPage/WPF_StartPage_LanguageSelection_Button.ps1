$WPF_StartPage_LanguageSelection_Button.Add_Click({
    Remove-Variable -Name 'WPF_LanguageSelectionWindow_*' 

    $WPF_LanguageSelectionWindow = Get-XAML -WPFPrefix 'WPF_LanguageSelectionWindow_' -XMLFile '.\Assets\WPF\Window_LanguageSettings.xaml'  -ActionsPath '.\Assets\UIActions\LanguageSettings\' -AddWPFVariables

    $CheckBoxes = Get-Variable -name "WPF_LanguageSelectionWindow_*" | Where-Object { $_.Value -is [System.Windows.Controls.CheckBox] } | Select-Object -ExpandProperty Value
    
    $OSandPackageLanguages = ((@(Get-InputFileCSV -CSV "OSLanguages").Language) + (@(Get-InputFileCSV -CSV "PackageLanguages").Language))  | Sort-Object -Unique
    
    foreach ($Checkbox in $CheckBoxes) {
        $NametoCheck = ($CheckBox.Name) -replace "_checkbox"
        If ($NametoCheck -eq "English") {
            $CheckBox.Add_PreviewMouseLeftButtonDown({
                param($sender, $e)
                $e.Handled = $true
            })
            $CheckBox.Add_PreviewKeyDown({
                param($sender, $e)
                $e.Handled = $true
            })
            $Checkbox.IsChecked = 1
            continue 
        }            
        if ($NametoCheck -notin $OSandPackageLanguages) {
            $varName = "WPF_LanguageSelectionWindow_$($Checkbox.Name)"
            Remove-Variable -Name $varName -Force -ErrorAction SilentlyContinue
            $Checkbox.Parent.Children.Remove($Checkbox) | Out-Null
        }
        else {
            if ($NametoCheck -in $Script:GUIActions.Languages){
                $Checkbox.IsChecked = 1
            }
            else {
                $Checkbox.IsChecked = 0
            }
        }
    }
   
    $WPF_LanguageSelectionWindow.ShowDialog() | out-null
    $WPF_LanguageSelectionWindow.close()
    
})

