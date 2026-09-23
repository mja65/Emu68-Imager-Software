$WPF_Window_Button_Run.Add_Click({
   if ($Script:GUICurrentStatus.FileBoxOpen -eq $true){
      return
   }
   
   Confirm-ValidPackageInstallDrives 
   
   Update-UI -CheckforRunningImage

   if ($Script:GUICurrentStatus.ProcessImageStatus -eq $false){
      Get-IssuesPriortoRunningImage
      return

   }
   elseif ($Script:GUICurrentStatus.ProcessImageStatus -eq $true){
      if ($Script:GUIActions.ScreenModetoUseFriendlyName -eq "Custom ScreenMode"){
         $Msg_Header = "Custom Screenmode Selected"
         $Msg_Body = @"
You have selected a custom screenmode! 

If you select an invalid mode and/or a mode your Raspberry Pi does not support you will not get a bootable system. Less likely but possible is that choosing the wrong screenmode details could cause issues with your Raspberry Pi or monitor. 

Press 'Yes' to confirm you really do wish to proceed using a custom screenmode (and acknowledge the risks) or press 'No' to go back to the Emu68 Imager to change to a standard screenmode
"@         
         
         $Response = Show-WarningorError -Msg_Body $Msg_Body -Msg_Header $Msg_Header -ButtonType_YesNo -BoxTypeWarning
         If ($Response -eq "No") {
            return
         }
      }
      Get-OptionsBeforeRunningImage
      if ($Script:GUICurrentStatus.ProcessImageConfirmedbyUser -eq $false){
         return
      }
      elseif ($Script:GUICurrentStatus.ProcessImageConfirmedbyUser -eq $true){

        # $Script:GUIActions.OutputType = "Disk"
        # $Script:GUIActions.OutputPath = "\disk6"
        $WPF_MainWindow.Close()
      }
   }
  
})   


