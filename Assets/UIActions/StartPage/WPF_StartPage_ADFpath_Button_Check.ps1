$WPF_StartPage_ADFpath_Button_Check.Add_Click({
    if ($Script:GUIActions.KickstartVersiontoUse){
        if ($Script:GUIActions.InstallMediaLocation){
            $ADFPathtoUse = $Script:GUIActions.InstallMediaLocation
        } 
        else{
            $ADFPathtoUse = $Script:Settings.DefaultInstallMediaLocation
        }
        $Script:GUIActions.FoundInstallMediatoUse = Compare-ADFHashes -MaximumFilestoCheck 500 -PathtoADFFiles $ADFPathtoUse -KickstartVersion $Script:GUIActions.KickstartVersiontoUse 
        
        if ((($Script:GUIActions.FoundInstallMediatoUse | Select-Object 'IsMatched' -unique).IsMatched -eq 'FALSE') -or (($Script:GUIActions.FoundInstallMediatoUse | Select-Object 'IsMatched' -unique).count -eq 2)) {
            $MissingFlag = $true
        }

        if ($MissingFlag -eq $true){
            $Title = 'Missing Install Files'
            $Text = 'You have missing Install Files. You need to correct this before you can run the tool. List of Install files located and missing is below'
        }
        else {                  
            $Title = 'Install Files to be used'
            $Text = 'The following Install Files will be used:'
        }
        
         $DatatoPopulate = $Script:GUIActions.FoundInstallMediatoUse | Select-Object @{Name='Status';Expression='IsMatched'},@{Name='Source';Expression='Source'},@{Name='Install File';Expression='FriendlyName'},@{Name='Path';Expression='Path'},@{Name='MD5 Hash';Expression='Hash'} | Sort-Object -Property 'Status'
    
         $FieldsSorted = ('Status','Source','Install File','Path','MD5 Hash')
    
         foreach ($ADF in $DatatoPopulate ){
             if ($ADF.Status -eq 'TRUE'){
                 $ADF.Status = 'Located'
             }
             else{
                 $ADF.Status = 'Missing!'
             }
         }

         Get-GUIADFKickstartReport -Title $Title -Text $Text -DatatoPopulate $DatatoPopulate -WindowWidth 800 -WindowHeight 350 -DataGridWidth 670 -DataGridHeight 200 -GridLinesVisibility 'None' -FieldsSorted $FieldsSorted    
         if ($MissingFlag -eq $true) {
            $Script:GUIActions.FoundInstallMediatoUse = $null
         }
         else {
            $Script:GUICurrentStatus.PackagesChanged = $null
            $Script:GUICurrentStatus.IconsChanged = $null
         }
         Update-UI -Emu68Settings -CheckforRunningImage
    }
    else{
        $null = Show-WarningorError -Msg_Body 'Cannot check ADFs as you have not yet chosen the OS!' -Msg_Header 'Error - No OS Chosen!'  -BoxTypeWarning -ButtonType_OK
    }
})
