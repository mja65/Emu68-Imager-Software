function Copy-CDFiles {
    param (
        [Switch]$SevenZip,
        [Switch]$HSTImager,
        $InputFile,
        $OutputDirectory,
        $FiletoExtract,
        $NewFileName
    )

    # $FiletoExtract = "OS-VERSION3.9\WORKBENCH3.5\Storage\DosDrivers\AUX"
    # $OutputDirectory = "Storage\DosDrivers"

    if ($SevenZip){
        Expand-CDFiles -SevenZip -InputFile $InputFile -OutputDirectory $OutputDirectory -FiletoExtract $FiletoExtract      
        $TempFoldertoExtract = [System.IO.Path]::GetFullPath("$($Script:Settings.TempFolder)\CDFilesSevenZip\")  
    }
    elseif ($HSTImager){
        Expand-CDFiles -HSTImager -InputFile $InputFile -OutputDirectory $OutputDirectory -FiletoExtract $FiletoExtract
        $TempFoldertoExtract = [System.IO.Path]::GetFullPath("$($Script:Settings.TempFolder)\CDFilesHSTImager\")
    }

    $OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory )

    if (-not (Test-Path -Path $OutputDirectory -PathType Container)){
        $null = New-Item -Path $OutputDirectory -ItemType Directory
    }
    
    if ($SevenZip){
        $FiletoExtract = "$(Split-Path $FiletoExtract -Parent)\_$(Split-Path $FiletoExtract -Leaf)"
    }

    if ($NewFileName){
        Write-InformationMessage -Message "Copying file $TempFoldertoExtract$FiletoExtract to $OutputDirectory with new name of $NewFileName"
        Copy-Item -Path "$TempFoldertoExtract$FiletoExtract" -Destination "$OutputDirectory\$NewFileName" -Force -Recurse 
    }
    else {
        # if ((Split-Path -path $FiletoExtract -Leaf) -match "Aux"){
        #     if ((Split-Path -path $FiletoExtract -Leaf) -eq "Aux"){
        #         $FiletoExtracttoUse  = "$(Split-Path $FiletoExtract -Parent)\_$(Split-Path $FiletoExtract -Leaf)"
        #     }
        #     else {
        #         $FiletoExtracttoUse = $FiletoExtract
        #     }
        #     $Script:GUICurrentStatus.HSTCommandstoProcess.CDExtractionCommands += [PSCustomObject]@{
        #         Command = "fs mkdir `"$OutputDirectory`""
        #         Sequence = 0
        #     }
        #     $Script:GUICurrentStatus.HSTCommandstoProcess.CDExtractionCommands += [PSCustomObject]@{
        #         Command = "fs copy `"$TempFoldertoExtract$FiletoExtracttoUse`" `"$OutputDirectory`" --uaemetadata None --recursive FALSE --makedir FALSE"
        #         Sequence = 1
        #     }
    
        # }
        # else {
            Write-InformationMessage -Message "Copying file $TempFoldertoExtract$FiletoExtract to $OutputDirectory"
            Copy-Item -Path "$TempFoldertoExtract$FiletoExtract" -Destination $OutputDirectory -Force -Recurse 
        # }
    }
    return $true

}
