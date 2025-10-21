$DropDownOptions = @()

$DropDownOptions += New-Object -TypeName pscustomobject -Property @{Option='Disk'}
$DropDownOptions += New-Object -TypeName pscustomobject -Property @{Option='Image'}

foreach ($Option in $DropDownOptions){
    $WPF_DP_MediaSelect_Type_DropDown.AddChild($Option.Option)
}

$WPF_DP_MediaSelect_Type_DropDown.SelectedItem = ''

$WPF_DP_MediaSelect_Type_DropDown.add_selectionChanged({
    if ($WPF_DP_MediaSelect_Type_DropDown.SelectedItem -eq 'Image'){
        if ($Script:GUIActions.OutputType -eq "Disk"){
            $Msg_Header = "Changing Output Device"
            $Msg_Body = "You are about to change the output device but you have already started setting up the disk. This will reset the disk set up. Please confirm you wish to do this."
            if ((Show-WarningorError -Msg_Header $Msg_Header -Msg_Body $Msg_Body -BoxTypeWarning -ButtonType_OKCancel) -eq 'OK'){
                
                $Script:GUICurrentStatus.SelectedAmigaPartition = $null
                $Script:GUICurrentStatus.SelectedGPTMBRPartition = $null
                $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = $null
                $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = $null
                $Script:GUIActions.OutputPath = $null
                $Script:GUIActions.InstallOSFiles = $true
                $Script:GUIActions.ImageSizeSelected = $null
                $Script:GUIActions.DiskSizeSelected = $null
                $Script:GUIActions.OutputType = "Image"          
                $Script:WPF_DP_MediaSelect_Type_DropDown.SelectedItem = $null
             
                Remove-Variable -Scope Script -Name 'WPF_DP_Partition*'
            
                if (test-path variable:script:WPF_DP_Disk_GPTMBR) {
                    Remove-Variable -Scope Script -Name 'WPF_DP_Disk_GPTMBR'
                }
            
                Update-UI -DiskPartitionWindow -freespacealert -HighlightSelectedPartitions

            }
            else {
                $WPF_DP_MediaSelect_Type_DropDown.SelectedItem = "Disk"
            }
        }
        else {
            $Script:GUIActions.OutputType = "Image"
        }            
    }
    elseif ($WPF_DP_MediaSelect_Type_DropDown.SelectedItem -eq 'Disk'){
        if ($Script:GUIActions.OutputType -eq "Image"){
            $Msg_Header = "Changing Output Device"
            $Msg_Body = "You are about to change the output device but you have already started setting up the disk. This will reset the disk set up. Please confirm you wish to do this."
            if ((Show-WarningorError -Msg_Header $Msg_Header -Msg_Body $Msg_Body -BoxTypeWarning -ButtonType_OKCancel) -eq 'OK'){
                            
                $Script:GUICurrentStatus.SelectedAmigaPartition = $null
                $Script:GUICurrentStatus.SelectedGPTMBRPartition = $null
                $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = $null
                $Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries = $null
                $Script:GUIActions.OutputPath = $null
                $Script:GUIActions.InstallOSFiles = $true
                $Script:GUIActions.ImageSizeSelected = $null
                $Script:GUIActions.DiskSizeSelected = $null
                $Script:GUIActions.OutputType = "Disk"        
            
                $Script:WPF_DP_MediaSelect_Type_DropDown.SelectedItem = $null
            
                Remove-Variable -Scope Script -Name 'WPF_DP_Partition*'
            
                if (test-path variable:script:WPF_DP_Disk_GPTMBR) {
                    Remove-Variable -Scope Script -Name 'WPF_DP_Disk_GPTMBR'
                }
            
                Update-UI -DiskPartitionWindow -freespacealert -HighlightSelectedPartitions
                
            }
            else {
                $WPF_DP_MediaSelect_Type_DropDown.SelectedItem = "Image"
            }   
        }
        else {
            $Script:GUIActions.OutputType = "Disk"   
        }     
    }

    update-ui -PhysicalvsImage

})



