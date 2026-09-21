function Get-PackagesfromInternet {
    param (
        
        $ListofPackagestoDownload

    )
  
    # $ListofPackagestoDownload = $CombinedOSandPackages
    
    $LogTempFolder = [System.IO.Path]::GetFullPath((join-path $Script:Settings.TempFolder "Logs"))
     if (-not(Test-Path $LogTempFolder -PathType Container)){
        $null = New-Item $LogTempFolder -ItemType Directory
    }

    $ListofPackagestoDownload = $ListofPackagestoDownload.where{($_.SourceType -notin @("UserFiles Local - Files", "Local - Files", "Local - Files - Config.txt", "Local - Files - Cmdline.txt"))} 

    $TotalDownloads = $ListofPackagestoDownload.count

    $UnADFFilePath = [System.IO.Path]::GetFullPath($Script:ExternalProgramSettings.UnADFFilePath) 
    $SevenZipFilePath = [System.IO.Path]::GetFullPath($Script:ExternalProgramSettings.SevenZipFilePath) 
    $UnLHAFilePath = [System.IO.Path]::GetFullPath($Script:ExternalProgramSettings.UnLHAFilePath)
    $UnLZXFilePath = [System.IO.Path]::GetFullPath($Script:ExternalProgramSettings.UnLZXFilePath)
       
    $SourceTypesforDownload = @('Web - Aminet','Web - Github','Web - AminetSearch','Web','Web - Github Emu68 Documentation','Web - WHDLoadWrapper')
    #$SourceTypesforDownload = $null
    $FileExtensionsforExtract = @('.lha','.zip','.lzx','.adf')
   # $FileExtensionsforExtract = $null
    $DownloadNumber = 0


   # foreach ($Line in ($ListofPackagestoDownload | where-object {$_.SourceLocation -eq "Roadshow - Demo.lha"})   ){

    foreach ( $Line in $ListofPackagestoDownload ){
        $DownloadNumber ++
        $DownloadFileExtension = [System.IO.Path]::GetExtension($line.OutputLocation)
        $NameofDLNoExtension  = [System.IO.Path]::GetFileNameWithoutExtension($line.OutputLocation)      
        Write-InformationMessage -Message  "Processing $($line.OutputLocation) `($DownloadNumber/$TotalDownloads`)" -NewLineBefore
        If (($Line.SourceType -in $SourceTypesforDownload) -and ($Line.DownloadFileFlag -eq $true)) {
            $DownloadSuccess = $false
            If ($Line.SourceType -match "Github"){
                $DownloadSuccess =  (Get-AmigaFileWeb -URL $Line.RevisedDownloadURL -LocationforDL $line.OutputLocation -NumberofAttempts 1)                
            } 
            else {
                $DownloadSuccess =  (Get-AmigaFileWeb -URL $Line.RevisedDownloadURL -AminetMirrors (Get-InputFileCSV -CSV 'AminetMirrors') -LocationforDL $line.OutputLocation -BackupURL $Line.BackupURL -NumberofAttempts 1)
            }
            if ($DownloadSuccess -eq $false){
                Write-ErrorMessage -Message "Error in downloaded packages! Unable to continue!"
                Write-InformationMessage -Message "Deleting package $($line.OutputLocation)"
                if (Test-path -Path $($line.OutputLocation)){
                    Remove-Item -Path $($line.OutputLocation) -Force -ErrorAction SilentlyContinue
                }
                exit                                    
            }  
            If ($Line.PerformHashCheck -eq $true){
                if ((Compare-FileHash -FiletoCheck $line.OutputLocation -HashtoCheck $Line.Hash -RunParallel $false) -eq $false){
                    Write-ErrorMessage -Message "Error in downloaded packages! Unable to continue!"
                    Write-InformationMessage -Message "Deleting package $($line.OutputLocation)"
                    if (Test-path -Path $($line.OutputLocation)){
                       Remove-Item -Path $($line.OutputLocation) -Force -ErrorAction SilentlyContinue
                    }
                    exit
                }
            }              
        }
        else {
            Write-InformationMessage -Message  "No Download required for $($line.OutputLocation)"
        }
        
        if ($DownloadFileExtension -in $FileExtensionsforExtract){
            If ($DownloadFileExtension -in @('.lha','.zip','.lzx')){
                $ExtractionFolder = Join-PathMulti $Script:Settings.WebPackagesDownloadLocation $NameofDLNoExtension -UseFullPath
            }
            elseif ($DownloadFileExtension -eq '.adf'){
                $ExtractionFolder = join-pathMulti $Script:Settings.ADFTemporaryFiles $Line.SourceLocation -UseFullPath
            }
            If (-not (Test-Path $ExtractionFolder -PathType Container)){
                $null = New-Item $ExtractionFolder -ItemType Directory
            }
            $FileNametoUse = if ($Line.SourceType -eq "UserFiles - Local - Archive" -or $Line.SourceType -eq "Local - Archive") { $Line.SourceLocation } else { $Line.OutputLocation }
            $DownloadstoProcess = @(
                [PSCustomObject]@{
                    ArchiveFileName = $FileNametoUse
                    ArchiveFileNameNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($FileNametoUse)
                    ArchiveFileExtension = [System.IO.Path]::GetExtension($FileNametoUse)
                    ExtractionFolder = $ExtractionFolder
                    CDParent = $Line.CDParent
                    UseLHASAFlag = $Line.UseLHASA
                    ArchivePassword = $null
                } 

            )
            if ($Line.ArchiveinArchiveName){
                $ExtractionFolderAiA =  join-path $ExtractionFolder "AiA"
                $ArchiveFileName = join-path $ExtractionFolder $Line.ArchiveinArchiveName
                If (-not (Test-Path $ExtractionFolderAiA -PathType Container)){
                    $null = New-Item $ExtractionFolderAiA -ItemType Directory
                }
             
                $DownloadstoProcess += @(
                    [PSCustomObject]@{
                        ArchiveFileName = $ArchiveFileName
                        ArchiveFileNameNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($ArchiveFileName)
                        ArchiveFileExtension = [System.IO.Path]::GetExtension($ArchiveFileName)
                        ExtractionFolder = $ExtractionFolderAiA
                        CDParent = $null
                        UseLHASAFlag = $Line.UseLHASA
                        ArchivePassword = $Line.ArchiveinArchivePassword
                    } 
                )
            
            }
            foreach ($DownloadtoProcess in $DownloadstoProcess) {
                 Write-InformationMessage -Message "Extracting files from: $($DownloadtoProcess.ArchiveFileName)"
                if ($DownloadtoProcess.ArchiveFileExtension -eq '.adf'){
                    $LogPathStandardOutput = Join-Path  $LogTempFolder "$($DownloadtoProcess.ArchiveFileNameNoExtension)LogStd.txt"
                    Write-informationMessage -Message "Extracting ADF $ArchiveFileName"
                    $OutputMessage = & $UnADFFilePath -d $ExtractionFolder $($DownloadtoProcess.ArchiveFileName) 2>&1 
                    If ($LASTEXITCODE -ne 0) {
                        Write-ErrorMessage -Message "Unable to extract ADF for $($DownloadtoProcess.ArchiveFileName)!"
                        $OutputMessage | Out-File -FilePath $LogPathStandardOutput -Encoding UTF8
                        exit
                    }
                }                   
                elseif ($DownloadtoProcess.ArchiveFileExtension -eq '.lzx'){
                    $LogPathStandardOutput = Join-Path  $LogTempFolder "$($DownloadtoProcess.ArchiveFileNameNoExtension)LogStd.txt"
                    Push-location -Path $DownloadtoProcess.ExtractionFolder
                    try {
                        & $UnlzxFilePath "$($DownloadtoProcess.ArchiveFileName)" 2>&1 | Out-File -FilePath $LogPathStandardOutput -Encoding UTF8
                        if ($LASTEXITCODE -ne 0) {
                            Write-ErrorMessage -Message "Error extracting $($DownloadtoProcess.ArchiveFileName)! Exiting"
                            exit

                        }
                    }
                    finally {
                        Pop-location
                    }
                }                    
                  
                elseif ($DownloadtoProcess.ArchiveFileExtension -eq '.lha' -and $DownloadtoProcess.UseLHASAFlag -match "TRUE"){
                    $LogPathStandardOutput = Join-Path  $LogTempFolder "$($DownloadtoProcess.ArchiveFileNameNoExtension)LogStd.txt"
                    try {
                        & $UnLHAFilePath "xfw=$($DownloadtoProcess.ExtractionFolder)" "$($DownloadtoProcess.ArchiveFileName)" 2>&1 | Out-File -FilePath $LogPathStandardOutput -Encoding UTF8
                        if (($DownloadtoProcess.UseLHASAFlag -ne "TRUE - NOCHECK") -and ($LASTEXITCODE -ne 0)) {
                            Write-ErrorMessage -Message "Error extracting $($DownloadtoProcess.ArchiveFileName)! Exiting"
                            exit
                        }
                    }
                    catch {
                        Write-ErrorMessage -Message "A critical scripting error occurred while running UnLHA: $_"
                        exit
                    }             
                 }
                else{
                    $LogPathStandardOutput = Join-Path  $LogTempFolder "$($DownloadtoProcess.ArchiveFileNameNoExtension)LogStd.txt"
                    if ($DownloadtoProcess.ArchivePassword){
                        & $SevenZipFilePath "x" "-o$($DownloadtoProcess.ExtractionFolder)" "-p$($DownloadtoProcess.ArchivePassword)" "$($DownloadtoProcess.ArchiveFileName)" "-y" 2>&1 | Out-File -FilePath $LogPathStandardOutput -Encoding UTF8                     
                    }
                    else {
                        & $SevenZipFilePath "x" "-o$($DownloadtoProcess.ExtractionFolder)" "$($DownloadtoProcess.ArchiveFileName)" "-y" 2>&1 | Out-File -FilePath $LogPathStandardOutput -Encoding UTF8                        
                    } 
                    if ($LASTEXITCODE -ne 0) {
                        Write-ErrorMessage -Message "Error extracting $($DownloadtoProcess.ArchiveFileName)! Exiting"
                        exit
                    }                       
                }   

            }
        }
    }         

}