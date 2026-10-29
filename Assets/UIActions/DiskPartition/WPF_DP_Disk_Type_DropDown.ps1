#$Script:GUIActions.DiskType = $null
#$WPF_DP_Disk_Type_DropDown.Items.Clear()
$ItemstoAdd = Get-InputFileCSV -CSV "DiskTypes" 
foreach ($item in $ItemstoAdd){
    $WPF_DP_Disk_Type_DropDown.AddChild($item.DiskTypeFriendlyName)
    If ($item.Default -eq $true){
 #       Write-Host "Default is true and populating $($item.DiskType)"
        $Script:GUIActions.DiskType = $item.DiskType
  #      Write-Host "Disktype is: $($Script:GUIActions.DiskType)"
    #    $WPF_DP_Disk_Type_DropDown.Selecteditem = $item.DiskTypeFriendlyName
    }
}

$WPF_DP_Disk_Type_DropDown.add_selectionChanged({
    if ($Script:GUICurrentStatus.LoadingSettings) {
        return
    }    
    
    #Write-Host "Start of Dropdown. Disktype is: $($Script:GUIActions.DiskType). Selected item is: $($WPF_DP_Disk_Type_DropDown.SelectedItem)"
    $ChangedDiskTypeDetails = (Get-InputFileCSV -CSV "DiskTypes").where({ $WPF_DP_Disk_Type_DropDown.SelectedItem -eq $_.DiskTypeFriendlyName })
    $PriorDiskTypeDetails = (Get-InputFileCSV -CSV "DiskTypes").where({ $_.DiskType -eq $Script:GUIActions.DiskType})  

    If (($Script:GUIActions.DiskType -eq 'MBR' -and $ChangedDiskTypeDetails.DiskType -eq 'GPT') -or ($Script:GUIActions.DiskType -eq 'GPT' -and $ChangedDiskTypeDetails.DiskType -eq 'MBR')) {
        $Msg_Header = "Changing Disk Type"
        $Msg_Body = "You are changing disk types but have already started setting up the disk. This will reset the set up. Please confirm you wish to do this."
        if ((Show-WarningorError -Msg_Header $Msg_Header -Msg_Body $Msg_Body -BoxTypeWarning -ButtonType_OKCancel) -eq 'Cancel'){
            $WPF_DP_Disk_Type_DropDown.SelectedItem = $PriorDiskTypeDetails.DiskTypeFriendlyName
            return
        }
    }

    #Write-Host "Passed check of changing DiskType. Disktype is: $($Script:GUIActions.DiskType)"
    #Write-Host "Trying to change Disktype through dropdown"
    $Script:GUIActions.DiskType = $ChangedDiskTypeDetails.DiskType
    #Write-Host "Changed Disktype. Disktype is now: $($Script:GUIActions.DiskType)"
    
    if ($Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries) {
        $SizeBytes = $Script:WPF_DP_Disk_GPTMBR.DiskSizeBytes
        $Script:GUICurrentStatus.SelectedAmigaPartition = $null
        $Script:GUICurrentStatus.SelectedGPTMBRPartition = $null
        $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = $null
        $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = $null
        $Script:GUIActions.OutputPath = $null
        $Script:GUIActions.ImageSizeSelected = $null
        $Script:GUIActions.OutputType = $null
        Remove-Variable -Scope Script -Name 'WPF_DP_Partition*'
        if (test-path variable:script:WPF_DP_Disk_GPTMBR) {
            Remove-Variable -Scope Script -Name 'WPF_DP_Disk_GPTMBR'
        }
        Set-InitialDiskValues -DiskType $Script:GUIActions.DiskType -SizeBytes $SizeBytes
    }
        
    Update-UI -DiskPartitionWindow -freespacealert -HighlightSelectedPartitions -MainWindowButtons -Emu68Settings
    return
    
})
    





    
    
    
    
    
