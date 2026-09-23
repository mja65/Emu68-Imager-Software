function Write-AvailableIconsets {
    param (
    )

    $Script:GUIActions.AvailableIconSets.Clear()
     
    $UserSelectableIconSets = @(Get-InputFileCSV -CSV 'IconSets').ForEach({
        [PSCustomObject]@{
            IconSet               = $_.IconSet
            IconSetDescription    = $_.IconSetDescription
            IconSetDefaultInstall = [System.Convert]::ToBoolean($_.IconsDefaultInstall)
        }
    })

    foreach ($line in  $UserSelectableIconSets){
       $RowData = @(
           $line.IconSet
           $line.IconSetDescription
           $line.IconSetDefaultInstall
       )
      [void]$Script:GUIActions.AvailableIconSets.Rows.Add($RowData)
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
