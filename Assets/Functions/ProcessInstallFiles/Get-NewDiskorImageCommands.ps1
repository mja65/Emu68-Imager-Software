function Get-NewDiskorImageCommands {
    param (
    )
    
    # $Script:GUIActions.OutputPath = "C:\Users\Matt\OneDrive\Documents\EmuImager2\UserFiles\SavedOutputImages\test.vhd"
  
    $DiskSizeBytestouse = $WPF_DP_Disk_GPTMBR.DiskSizeBytes 
       
    $Script:Settings.CurrentSubTaskName = "Getting HST commands"
    
    Write-StartSubTaskMessage

    if ($Script:GUIActions.OutputType -eq 'Image'){
        Write-InformationMessage -Message "Virtualised disk being used"
        if (Test-Path $Script:GUIActions.OutputPath){
            Write-InformationMessage -Message "Removing existing image: $($Script:GUIActions.OutputPath)"
            $Null = Remove-Item -Path $Script:GUIActions.OutputPath -Force
        }    
        Write-InformationMessage -Message "Creating a Virtual Image at: $($Script:GUIActions.OutputPath)"
        $Script:GUICurrentStatus.HSTImagerCommandstoProcess.NewDiskorImage += [PSCustomObject]@{
            Command = "blank `"$($Script:GUIActions.OutputPath)`" $DiskSizeBytestouse"
            Sequence = 1
        }
          
    }
      
    elseif ($Script:GUIActions.OutputType -eq 'Disk'){
        $CleanDiskFile = Join-PathMulti $Script:Settings.TempFolder "Clean.vhd" -UseFullPath
        Write-InformationMessage -Message "Physical disk being used"
        if (test-path $CleanDiskFile){
            $null = Remove-Item $CleanDiskFile
        }
        Write-InformationMessage -Message "Adding commands to wipe disk"
      
        $Script:GUICurrentStatus.HSTImagerCommandstoProcess.NewDiskorImage += [PSCustomObject]@{
            Command = "blank `"$CleanDiskFile`" 5mb"
            Sequence = 1
        }
        $Script:GUICurrentStatus.HSTImagerCommandstoProcess.NewDiskorImage += [PSCustomObject]@{
            Command = "write `"$CleanDiskFile`" $($Script:GUIActions.OutputPath) --skip-unused-sectors FALSE" 
            Sequence = 2 
        }
    }
    else {
        Write-ErrorMessage -Message "Error in Coding - WPF_Window_Button_Run !"
        $WPF_MainWindow.Close()
        exit
    }
      
}
