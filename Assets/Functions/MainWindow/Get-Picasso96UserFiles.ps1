function Get-Picasso96UserFiles {
        param (
            $Picasso96FilesPath,
            $DestinationPath
        )
    
        # $Picasso96FilesPath = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\UserFiles\ExistingApplications"
        
        $HSTPath = $([System.IO.Path]::GetFullPath("$($Script:ExternalProgramSettings.HSTImagerPath)"))
        # $HSTAmigaPath = $([System.IO.Path]::GetFullPath("$($Script:ExternalProgramSettings.HSTAmigaPath)")) 
        $HSTCommands = [System.Collections.Generic.List[PSCustomObject]]::New()
        
        $Picasso96Path = (Get-ChildItem -Path $Picasso96FilesPath -Recurse | Where-Object {$_.name -match "Picasso96-3." -and [System.IO.Path]::GetExtension($_.name)-eq ".lha"} | Select-Object -First 1)
    
        If (-not ($Picasso96Path)){
            return
        }   

        $CheckPath = "$($Picasso96Path.FullName)\Picasso96Install\Libs\Picasso96\rtg.library"
        $Check = & "$HSTPath" fs dir "$CheckPath"

        $SummaryLine = $Check | Select-String -Pattern "\d+ files?"
        if ($SummaryLine -match '(?<Count>\d+)\s+files?') {
            $FileCount = [int]$Matches['Count']
        }
        
        if ($FileCount -eq 1){
            $HSTCommands += [PSCustomObject]@{ Command = "fs extract `"$($Picasso96Path.FullName)\Picasso96Install\Libs\*`" `"$DestinationPath\Libs`" --makedir TRUE --uaemetadata UaeFsDb --force TRUE"; Sequence = 1 }
            $HSTCommands += [PSCustomObject]@{ Command = "fs extract `"$($Picasso96Path.FullName)\Picasso96Install\Picasso96\*`" `"$DestinationPath\Programs\Picasso96`" --makedir TRUE --uaemetadata UaeFsDb --force TRUE"; Sequence = 1 }
            $HSTCommands += [PSCustomObject]@{ Command = "fs extract `"$($Picasso96Path.FullName)\Picasso96Install\Prefs\*`" `"$DestinationPath\Prefs`" --makedir TRUE --uaemetadata UaeFsDb --force TRUE"; Sequence = 1 }
            $HSTCommands += [PSCustomObject]@{ Command = "fs delete `"$DestinationPath\Prefs\PVS`" --uaemetadata UaeFsDb --force TRUE"; Sequence = 1 }
            $HSTCommands += [PSCustomObject]@{ Command = "fs delete `"$DestinationPath\Prefs\PVS.info`" --uaemetadata UaeFsDb --force TRUE"; Sequence = 1 }
            $HSTCommands += [PSCustomObject]@{ Command = "fs delete `"$DestinationPath\Prefs\PVS.guide`" --uaemetadata UaeFsDb --force TRUE"; Sequence = 1 }
            $HSTCommands += [PSCustomObject]@{ Command = "fs delete `"$DestinationPath\Prefs\PVS.guide.info`" --uaemetadata UaeFsDb --force TRUE"; Sequence = 1 }
            return $HSTCommands
        }
        else {
            return
        }
    }