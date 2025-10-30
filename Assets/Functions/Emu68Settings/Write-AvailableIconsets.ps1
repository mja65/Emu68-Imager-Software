function Write-AvailableIconsets {
    param (
    )
    $Script:GUIActions.AvailableIconSets.Clear()
    # $UserSelectableIconSets  = Get-InputCSVs -IconSets | Select-Object @{Name='IconSet';Expression = 'IconSetName'},'IconSetDescription',@{Name='IconSetUserSelected';Expression = 'IconsDefaultInstall'},@{Name='IconSetDefaultInstall';Expression = 'IconsDefaultInstall'}
    
    $UserSelectableIconSets  = Get-InputCSVs -IconSets | Select-Object @{Name='IconSet';Expression = 'IconSetName'},'IconSetDescription',@{Name='IconSetDefaultInstall';Expression = 'IconsDefaultInstall'}
    
    foreach ($line in  $UserSelectableIconSets){
       $Array = @()
       $array += $line.IconSet
       $array += $line.IconSetDescription
       $array += $line.IconSetDefaultInstall
      # $array += $line.IconSetUserSelected
       [void]$Script:GUIActions.AvailableIconSets.Rows.Add($array)
    }
    
    if (-not ($Script:GUIActions.SelectedIconSet)){
        $UserSelectableIconSets | ForEach-Object {
            if ($_.IconSetDefaultInstall -eq $true){
                $Script:GUIActions.SelectedIconSet = $_.IconSet
                if ($Script:GUICurrentStatus.OperationMode -eq "Advanced"){
                    $WPF_PackageSelection_CurrentlySelectedIconSet_Value.text = $_.IconSet
                }
            }
        }
    }

}
