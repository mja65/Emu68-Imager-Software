function Expand-AmigaZFiles {
    param (
        $LocationofZFiles,
        [switch]$MultipleDirectoryFlag

    )
    
    # $LocationofZFiles = "C:\Users\Matt\OneDrive\Documents\EmuImager2\Temp\InterimAmigaDrives\System\Locale"
    # $LocationofZFiles =  "$($Script:Settings.InterimAmigaDrives)\System"

    $CurrentLocation = Get-Location

    #Write-host $CurrentLocation 

    $SevenzipPathtouse  = [System.IO.Path]::GetFullPath($Script:ExternalProgramSettings.SevenZipFilePath)
    $LogLocation = [System.IO.Path]::GetFullPath($Script:Settings.LogLocation)

    #Write-debug "Location of Z Files [$LocationofZFiles]"

    if ($MultipleDirectoryFlag){
        $DirectoriestoDecompress = ((Get-ChildItem -LiteralPath $LocationofZFiles -Recurse -Filter '*.Z').Directory).FullName 
        $UniqueDirectoriestoDecompress = $DirectoriestoDecompress | Select-Object -Unique 
        $TotalFolders = $UniqueDirectoriestoDecompress.Count
        $FoldersDone = 0
        foreach ($Directory in $UniqueDirectoriestoDecompress){
            $FoldersDone ++
            $newPercent = [math]::Floor(($FoldersDone/$TotalFolders)*100)
            if ($newPercent -ne $percentComplete  -and $newPercent % 10 -eq 0) {
                $percentComplete = $newPercent
                Write-Progress -Activity "Extracting .Z files" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
            }
            #Write-InformationMessage -Message "Decompressing .Z files in location: $Directory" -LogLocation $LogLocation
            set-location $Directory 
            & $SevenzipPathtouse e *.z -bso0 -bsp0 -y                       
                               
        }
        Write-Progress -Activity "Extracting .Z files" -Completed -Status "Done"
    }
    else {
        $ListofFilestoDecompress = Get-ChildItem -Path $LocationofZFiles -Recurse -Filter '*.Z'
        Write-InformationMessage -Message "Decompressing .Z files in location: $LocationofZFiles" 
        foreach ($FiletoDecompress in $ListofFilestoDecompress){
            $InputFile = $FiletoDecompress.FullName
            set-location $FiletoDecompress.DirectoryName
            & $SevenzipPathtouse e $InputFile -bso0 -bsp0 -y
        }    
        
    }

    Set-Location $CurrentLocation
    
    Write-InformationMessage -Message "Deleting .Z files in location: $LocationofZFiles"

    Show-SpinnerWhileDeleting -ScriptBlock {
        Get-ChildItem -Path $using:LocationofZFiles -Filter "*.Z" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    
}

