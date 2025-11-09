function Copy-CDFiles {
    param (
        [Switch]$SevenZip,
        [Switch]$HSTImager,
        $InputFile,
        $OutputDirectory,
        $FiletoExtract,
        $NewFileName
    )

    #  $SevenzipPathtouse = 'E:\Emu68Imager\Programs\7z.exe'
    #  $TempFoldertouse = 'E:\Emu68Imager\Working Folder\Temp\'
    #  $InputFile = 'E:\Emulators\Amiga Files\3.9\AmigaOS39-p00h.iso'
    #  $FiletoExtract = 'OS-VERSION3.9\WORKBENCH3.5\Tools\HDToolBox.info'
    #  $OutputDirectory = 'E:\Emu68Imager\Working Folder\AmigaImageFiles\Workbench\Tools\'
    #  $NewFileName = 'HDToolBoxPi3.info'

    # $InputFile = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\UserFiles\InstallMedia\AmigaOS39-p00h.iso"
    # $OutputDirectory = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\IconFiles\NewFolderIcon"
    # $FiletoExtract = "OS-Version3.9\Icons\drawer.info"

    # Write-debug "Input file is: [$InputFile] Output Directory is: [$OutputDirectory] File to Extract is: [$FiletoExtract] New File Name is: [$NewFileName]"
    
    $TempFoldertoExtract = "$($Script:Settings.TempFolder)\CDFiles\"

    # Write-debug "Temporary folder to extract to is: $TempFoldertoExtract"

    if (-not (Test-Path $TempFoldertoExtract)){
        $null = New-Item $TempFoldertoExtract -ItemType Directory -Force
    }
    
    $ParentFolder = $FiletoExtract.split("\")[0]
    $ExtractedFilesPath = "$TempFoldertoExtract$ParentFolder"

    if (-not (Test-path $ExtractedFilesPath)){
        Write-InformationMessage -Message "No existing extracted files. Extracting $ParentFolder"
        if ($SevenZip){
            $TempFoldertoUse = [System.IO.Path]::GetFullPath($Script:Settings.TempFolder)
            & $Script:ExternalProgramSettings.SevenZipFilePath x ('-o'+$TempFoldertoExtract) $InputFile $ParentFolder -y >($TempFoldertouse+'LogOutputTemp.txt')
    
            if ($LASTEXITCODE -ne 0) {
                Write-ErrorMessage -Message ('Error extracting '+$InputFile+'! Cannot continue!')
                return $false    
            }
        }
        if ($HSTImager){
            $TempFoldertoExtract = [System.IO.Path]::GetFullPath($TempFoldertoExtract)
            $Commandtouse = [PSCustomObject]@{
                Command = "fs extract `"$InputFile\*`" `"$TempFoldertoExtract`" --uaemetadata UaeFsDb --recursive"
            }
                
            Start-HSTCommands -HSTScript $Commandtouse -TotalSteps 7609 -ActivityDescription "Running HST Imager to extract OS files"            
        }
    } 
    # else {
    #     Write-InformationMessage -Message "$ParentFolder exists. Files already extracted."
    # }

    if (-not (Test-Path -Path $OutputDirectory -PathType Container)){
        $null = New-Item -Path $OutputDirectory -ItemType Directory
    }
    
    if ($NewFileName){
        Write-InformationMessage -Message "Copying file $TempFoldertoExtract$FiletoExtract to $OutputDirectory with new name of $NewFileName"
        Copy-Item -Path "$TempFoldertoExtract$FiletoExtract" -Destination "$OutputDirectory\$NewFileName" -Force -Recurse 
    }
    else {
        Write-InformationMessage -Message "Copying file $TempFoldertoExtract$FiletoExtract to $OutputDirectory"
        Copy-Item -Path "$TempFoldertoExtract$FiletoExtract" -Destination $OutputDirectory -Force -Recurse 
    }

            return $true
}