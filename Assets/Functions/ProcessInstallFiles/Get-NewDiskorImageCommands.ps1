function Get-NewDiskorImageCommands {
    param (
        $OutputLocationType
    )
    
    # $Script:GUIActions.OutputPath = "C:\Users\Matt\OneDrive\Documents\EmuImager2\UserFiles\SavedOutputImages\test.vhd"

  
    $TempFoldertouse = [System.IO.Path]::GetFullPath($Script:Settings.TempFolder)
    $DiskSizeBytestouse = $WPF_DP_Disk_GPTMBR.DiskSizeBytes 
    
    $Script:GUICurrentStatus.HSTCommandstoProcess.NewDiskorImage = [System.Collections.Generic.List[PSCustomObject]]::New()
    
    $Script:Settings.CurrentSubTaskNumber = 1
    $Script:Settings.CurrentSubTaskName = "Getting HST commands"
    
    Write-StartSubTaskMessage

    if (($OutputLocationType -eq 'VHDImage') -or ($OutputLocationType -eq 'IMGImage')){
        Write-InformationMessage -Message "Virtualised disk being used"
        Write-InformationMessage -Message "Creating a Virtual Image at: $($Script:GUIActions.OutputPath)"
        if (Test-Path $Script:GUIActions.OutputPath){
            $IsMounted = (Get-DiskImage -ImagePath $Script:GUIActions.OutputPath -ErrorAction Ignore).Attached
            if ($IsMounted -eq $true){
                Write-InformationMessage -Message "Dismounting existing image: $($Script:GUIActions.OutputPath)"
                $null = Dismount-DiskImage -ImagePath $Script:GUIActions.OutputPath 
            }
            Write-InformationMessage -Message "Removing existing image: $($Script:GUIActions.OutputPath)"
            $Null = Remove-Item -Path $Script:GUIActions.OutputPath -Force
        }    
        
        $Script:GUICurrentStatus.HSTCommandstoProcess.NewDiskorImage += [PSCustomObject]@{
            Command = "blank `"$($Script:GUIActions.OutputPath)`" $DiskSizeBytestouse"
            Sequence = 1           
         }
   
    }
      
    elseif ($OutputLocationType -eq 'Physical Disk'){
        Write-InformationMessage -Message "Physical disk being used"
        if (test-path "$TempFoldertouse\Clean.vhd"){
            $null = Remove-Item "$TempFoldertouse\Clean.vhd"
        }
        Write-InformationMessage -Message 'Adding commands to wipe disk'
      
        $Script:GUICurrentStatus.HSTCommandstoProcess.NewDiskorImage += [PSCustomObject]@{
            Command = "blank `"$TempFoldertouse\Clean.vhd`" 5mb"
            Sequence = 1
        }
        $Script:GUICurrentStatus.HSTCommandstoProcess.NewDiskorImage += [PSCustomObject]@{
            Command = "write `"$TempFoldertouse\Clean.vhd`" `"$($Script:GUIActions.OutputPath)`" --skip-unused-sectors FALSE" 
            Sequence = 2 
        }
    }
    else {
        Write-ErrorMessage -Message "Error in Coding - WPF_Window_Button_Run !"
        $WPF_MainWindow.Close()
        exit
    }
      
}
