 $WPF_StartPage_ROMpath_Button_Check.Add_Click({
    if ($Script:GUIActions.KickstartVersiontoUse){
        if ($Script:GUIActions.ROMLocation){
            $RomPathtoUse = $Script:GUIActions.ROMLocation
        } 
        else{
            $RomPathtoUse = $Script:Settings.DefaultROMLocation
        }
        $FoundKickstarts = Compare-KickstartHashes -PathtoKickstartFiles $RomPathtoUse -MaximumFilestoCheck 500
        $Script:GUIActions.FoundKickstarttoUse = @($FoundKickstarts.where({$_.status -ne "Not Found"}))
        $KickstartVersionFound = $Script:GUIActions.FoundKickstarttoUse.where({($_.KickstartVersion)}).KickstartVersion
        $ExcludedKickstartFound = $Script:GUIActions.FoundKickstarttoUse.where({ ($_.KickstartVersion) -and $_.IncludeorExclude -eq 'Exclude'})
        if (-not ($KickstartVersionFound)){
            $null = Show-WarningorError -Msg_Header 'Error - No Kickstart found!' -Msg_Body 'No valid Kickstart file was found at the location you specified. Select a location with a valid Kickstart file.' -BoxTypeWarning -ButtonType_OK 
        }
        elseif ($ExcludedKickstartFound){
            $MessagetoWrite = "$($ExcludedKickstartFound.ExcludeMessage) $($ExcludedKickstartFound.KickstartPath)"
            $null = Show-WarningorError -Msg_Header 'Error - Encrypted Kickstart found!' -Msg_Body $MessagetoWrite -BoxTypeWarning -ButtonType_OK 
            $Script:GUIActions.FoundKickstarttoUse = $null
        }
        else{
            $FieldsSorted = ('Type','Status','Kickstart','Path')
            $Title = 'Kickstarts to be used'
            $Text = 'The following Kickstarts will be used. If found, relevant Kickstart ROMs will be copied to Devs/Kickstarts for use in WHDLoad:'
            $DatatoPopulate = $FoundKickstarts | Select-Object @{
                Name = 'Type'
                Expression = { 
                    if (($_.WHDLoadName) -and ($_.KickstartVersion)) {
                        "Main Kickstart ROM and WHDLoad ROM" 
                    }
                    elseif ($_.WHDLoadName) {
                        "WHDLoad ROM"
                    }
                    elseif ($_.KickstartVersion) {
                        "Main Kickstart ROM"
                    }
                }
            },
            @{
                Name = 'Status'
                Expression = 'Status'

            },
            @{
                Name='Kickstart'
                Expression='FriendlyName'
            },
            @{
                Name='Path'
                Expression='KickstartPath'
            }         
        
            Get-GUIADFKickstartReport -Title $Title -Text $Text -DatatoPopulate $DatatoPopulate -WindowWidth 700 -WindowHeight 300 -DataGridWidth 570 -DataGridHeight 180 -GridLinesVisibility 'None' -FieldsSorted $FieldsSorted    
        
        }
    }
    else{
        $null = Show-WarningorError -Msg_Header 'Error - No OS Chosen!'  -Msg_Body 'Cannot check Kickstarts as you have not yet chosen the OS!' -BoxTypeWarning -ButtonType_OK 
    }
    
    Update-UI -Emu68Settings -CheckforRunningImage
    
})
