 function Get-PackagesfromInternetParallel {
    param (
        $ListofOSPackages,
        $ListofNonOSPackages
    )

    
    # $ListofNonOSPackages = $ListofPackagestoInstall
    # $ListofOSPackages = ($ListofOSPackagestoInstall.where({$_.SourceType -ne "CD"}))   
   # $ListofOSPackages = $null

    $ListofNonOSPackages = $ListofNonOSPackages.where{($_.SourceType -notin @("UserFiles Local - Files", "Local - Files", "Local - Files - Config.txt", "Local - Files - Cmdline.txt"))} 
   
    #$ListofNonOSPackages = $null

   #$ListofNonOSPackages | Export-Csv -Path "test.txt" -delimiter ";" -NoTypeInformation

    Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue

    Remove-TempFolderFiles
    
    #$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $AminetMirrors = Get-InputFileCSV -CSV 'AminetMirrors'
    $IsProcessedSOSPackages = $false

    $BatchSize = 3 
    $Index = 0
 
    $Jobs = @()

    $ParallelRunDebugLogFolder = join-pathMulti $Script:Settings.TempFolder "ParallelRunDebugLogs" -UseFullPath

    if (Test-Path $ParallelRunDebugLogFolder){
        $null = Remove-Item -Path $ParallelRunDebugLogFolder -Recurse -Force
    } 

    $null = New-Item -Path $ParallelRunDebugLogFolder -ItemType Directory

    while ($Index -lt $ListofNonOSPackages.Count -or ($ListofOSPackages.Count -gt 0 -and -not $IsProcessedSOSPackages)) {
        If (-not $IsProcessedSOSPackages -and $ListofOSPackages.Count -gt 0) {
            $IsProcessedSOSPackages = $true
            $CurrentBatch = $ListofOSPackages
        }
        else {
            $EndIndex = [Math]::Min(($Index + $BatchSize - 1), ($ListofNonOSPackages.Count - 1))
            $CurrentBatch = $ListofNonOSPackages[$Index..$EndIndex]
            $Index += $BatchSize        
        }
    
        $ThreadArgs = @{
            HSTImagerPath = [System.IO.Path]::GetFullPath($Script:ExternalProgramSettings.HSTImagerPath)
            WebPackagesDownloadLocation = [System.IO.Path]::GetFullPath($Script:Settings.WebPackagesDownloadLocation)
            ADFTemporaryFiles = [System.IO.Path]::GetFullPath($Script:Settings.ADFTemporaryFiles)
            CDTemporaryFiles = [System.IO.Path]::GetFullPath($Script:Settings.CDTemporaryFiles) 
            TempFolder = [System.IO.Path]::GetFullPath($Script:Settings.TempFolder)
            ParallelRunDebugLogFolderToUse = $ParallelRunDebugLogFolder
            SevenZipFilePath = [System.IO.Path]::GetFullPath($Script:ExternalProgramSettings.SevenZipFilePath) 
            UnADFFilePath = [System.IO.Path]::GetFullPath($Script:ExternalProgramSettings.UnADFFilePath) 
            UnLHAFilePath = [System.IO.Path]::GetFullPath($Script:ExternalProgramSettings.UnLHAFilePath)
            UnLZXFilePath = [System.IO.Path]::GetFullPath($Script:ExternalProgramSettings.UnLZXFilePath)
            Packages = $CurrentBatch
            Mirrors  = $AminetMirrors
        }

        $Jobs += Start-ThreadJob -ThrottleLimit 50 -ArgumentList $ThreadArgs -ScriptBlock {

            param($Bundle)
    
            $PackageList = $Bundle.Packages
            $Mirrors     = $Bundle.Mirrors
            $CDTemporaryFiles = $Bundle.CDTemporaryFiles
            $ADFTemporaryFiles = $Bundle.ADFTemporaryFiles
            $WebPackagesDownloadLocation = $Bundle.WebPackagesDownloadLocation
            $HSTImagerPath = $Bundle.HSTImagerPath
            $TempFolder = $Bundle.TempFolder
            $ParallelRunDebugLogFolderToUse = $Bundle.ParallelRunDebugLogFolderToUse
            $SevenZipFilePath = $Bundle.SevenZipFilePath 
            $UnLHAFilePath = $Bundle.UnLHAFilePath  
            $UnADFFilePath = $Bundle.UnADFFilePath
            $UnLZXFilePath = $Bundle.UnLZXFilePath
                           
            . .\Assets\Functions\Get-AmigaFileWeb.ps1
            . .\Assets\Functions\Join-PathMulti.ps1
            . .\Assets\Functions\ProcessInstallFiles\Write-AmigaFilestoInterimDrive\Compare-FileHash.ps1

            $Results = [System.Collections.Generic.List[PSObject]]::new()
            
            # $ThreadID = [System.Threading.Thread]::CurrentThread.ManagedThreadId
            # $DebugLog = join-path $ParallelRunLogFolder "Thread$($ThreadID)_ParallelJob_Debug.log"                    
            # $StartTime = [datetime]::Now
            # "$($StartTime.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Starting Job" | Out-File $DebugLog -Append
       
            foreach ($Line in $PackageList) {
                $DownloadstoProcess = @()
                $BypassExtractofDL = $false                
                $Result_AIA = $null                
                $Time = (Get-Date -Format "HH:mm:ss")
                $ThreadDetails = "[Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId)][$Time] Dedicated OS"
                $FileNametoUse = if ($Line.SourceType -eq "UserFiles - Local - Archive" -or $Line.SourceType -eq "Local - Archive") { $Line.SourceLocation } else { $Line.OutputLocation }
                $Result = [PSCustomObject]@{
                    Thread                             = $ThreadDetails
                    FileName                           = $FileNametoUse
                    CDParent                           = $Line.CDParent
                    ArchivePassword                    = $null
                    DownloadStatus                     = $null
                    PerformHashCheckonDL               = $line.PerformHashCheck
                    HashCheckFailed                    = $false 
                    DownloadSuccess                    = $false
                    AiA                                = $false
                    ExtractFiles                       = $false
                    FileNamewithoutExtension           = $null
                    UseLHASAFlag                       = $Line.UseLHASA
                    FileNameExtension                  = $null
                    ExtractionFolder                   = $null
                    ExtractionSuccess                  = $false
                    ExtractMessage                     = $null   
                }
    
                $SourceTypesforDownload = @('Web - Aminet','Web - Github','Web - AminetSearch','Web','Web - Github Emu68 Documentation','Web - WHDLoadWrapper')
                $Result.FileNameExtension = [System.IO.Path]::GetExtension($FileNametoUse)
                $Result.FileNamewithoutExtension  = [System.IO.Path]::GetFileNameWithoutExtension($FileNametoUse)  
                if ($Result.FileNameExtension -in @('.lha','.zip','.lzx','.iso','.adf')){
                    $Result.ExtractFiles = $true
                }
                If ($Result.FileNameExtension -in @('.lha','.zip','.lzx')){
                    $Result.ExtractionFolder = Join-PathMulti $WebPackagesDownloadLocation $Result.FileNamewithoutExtension -UseFullPath
                }
                elseif ($Result.FileNameExtension -eq '.adf'){
                    $Result.ExtractionFolder = Join-PathMulti $ADFTemporaryFiles $Line.SourceLocation -UseFullPath             
                }
                if ($Line.SourceType -in $SourceTypesforDownload){
                    if ($Line.DownloadFileFlag -eq $true) {
                        $Result.DownloadStatus = "To Be Downloaded"                    
                    }
                    else {
                        $Result.DownloadStatus = "Already Downloaded"
                    }
                }
                else {
                    $Result.DownloadStatus = "Not Needed" 
                }
                if ($Result.DownloadStatus -eq "To Be Downloaded") {
                    if ($Line.SourceType -match "Github"){
                        $result.DownloadSuccess = (Get-AmigaFileWeb -URL $Line.RevisedDownloadURL -LocationforDL $Result.FileName -NumberofAttempts 1 -RunParallel $true -ParallelRunLogFolder $ParallelRunDebugLogFolderToUse)                
                    } 
                    else {
                        $result.DownloadSuccess = (Get-AmigaFileWeb -URL $Line.RevisedDownloadURL -AminetMirrors $Mirrors -LocationforDL $Result.FileName -BackupURL $Line.BackupURL -NumberofAttempts 1 -RunParallel $true -ParallelRunLogFolder $ParallelRunDebugLogFolderToUse)
                    }
                    if ($result.DownloadSuccess -ne $true){
                        Remove-Item -Path $Result.FileName -Force -ErrorAction SilentlyContinue
                        $BypassExtractofDL = $true
                    }
                    if ($Result.PerformHashCheckonDL -eq $true){
                        if ((Compare-FileHash -FiletoCheck $Result.FileName -HashtoCheck $Line.Hash -RunParallel $true) -eq $false){
                            $Result.HashCheckFailed = $true
                            Remove-Item -Path $Result.FileName -Force -ErrorAction SilentlyContinue
                            $BypassExtractofDL = $true
                        }
                    }
                }   
                if ($Result.ExtractionFolder) {
                    If (-not (Test-Path $Result.ExtractionFolder -PathType Container)){
                        $null = New-Item $Result.ExtractionFolder -ItemType Directory
                    }
                } 
                                      
                if ($Line.ArchiveinArchiveName){
                    $FileName_AIA = join-path $Result.ExtractionFolder $Line.ArchiveinArchiveName
                    $Result_AIA = [PSCustomObject]@{
                        Thread                             = $ThreadDetails
                        FileName                           = $FileName_AIA
                        CDParent                           = $null
                        ArchivePassword                    = $Line.ArchiveinArchivePassword
                        DownloadStatus                     = "Not Needed" 
                        PerformHashCheckonDL               = $null
                        HashCheckFailed                    = $false 
                        DownloadSuccess                    = $false
                        AiA                                = $true
                        ExtractFiles                       = $true
                        FileNamewithoutExtension           = [System.IO.Path]::GetFileNameWithoutExtension($FileName_AIA)
                        UseLHASAFlag                       = $null
                        FileNameExtension                  = [System.IO.Path]::GetExtension($FileName_AIA)
                        ExtractionFolder                   = join-path $Result.ExtractionFolder "AiA"
                        ExtractionSuccess                  = $false   
                        ExtractMessage                     = $null                     
                    }                                                    
                    if ($Result_AIA.ExtractionFolder) {
                        If (-not (Test-Path $Result_AIA.ExtractionFolder -PathType Container)){
                            $null = New-Item $Result_AIA.ExtractionFolder -ItemType Directory
                        }      
                    }                     
                }
                if ($BypassExtractofDL -eq  $true){
                    #"$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Unable to DL: $($Line.RevisedDownloadURL)" | Out-File $DebugLog -Append 
                    $DownloadstoProcess = @()    
                }
                else {
                    $DownloadstoProcess = @($Result)
                    if ($null -ne $Result_AIA) {
                        $DownloadstoProcess += $Result_AIA          
                    }
                }
                if ($DownloadstoProcess){
                    foreach ($DownloadtoProcess in $DownloadstoProcess) {
                        if ($DownloadtoProcess.FileNameExtension -eq '.adf'){
                            $OutputMessage = & $UnADFFilePath -d $DownloadtoProcess.ExtractionFolder $($DownloadtoProcess.FileName) 2>&1 
                            If ($LASTEXITCODE -ne 0) {
                                If ($DownloadtoProcess.AiA){
                                    $Result_AIA.ExtractionSuccess = $false
                                    $Result_AIA.ExtractMessage = $OutputMessage
                                }
                                else {
                                    $Result.ExtractionSuccess = $false
                                    $Result.ExtractMessage = $OutputMessage
                                }                            
                            }
                            else {
                                If ($DownloadtoProcess.AiA){
                                    $Result_AIA.ExtractionSuccess = $true
                                }
                                else {
                                    $Result.ExtractionSuccess = $true
                                }                                
                            }                    
                        }
                        elseif ($DownloadtoProcess.FileNameExtension -eq '.lha' -and $DownloadtoProcess.UseLHASAFlag -match "TRUE"){
                            try {
                                $OutputMessage = & $UnLHAFilePath "xfw=$($DownloadtoProcess.ExtractionFolder)" "$($DownloadtoProcess.FileName)" 2>&1
                                If ($DownloadtoProcess.AiA){
                                    $Result_AIA.ExtractionSuccess = $true
                                }
                                else {
                                    $Result.ExtractionSuccess = $true
                                }                                
                            }
                            catch {
                                If ($DownloadtoProcess.AiA){
                                    $Result_AIA.ExtractionSuccess = $false
                                    $Result_AIA.ExtractMessage = $OutputMessage
                                }
                                else {
                                    $Result.ExtractionSuccess = $false
                                    $Result.ExtractMessage = $OutputMessage
                                }                              
                            }       
                        }
                        elseif ($DownloadtoProcess.FileNameExtension -eq '.lzx'){
                            Push-location -Path $DownloadtoProcess.ExtractionFolder
                            try {
                                $OutputMessage = & $UnlzxFilePath "$($DownloadtoProcess.FileName)" 2>&1
                                if ($LASTEXITCODE -ne 0) {
                                    If ($DownloadtoProcess.AiA){
                                        $Result_AIA.ExtractionSuccess = $false
                                        $Result_AIA.ExtractMessage = $OutputMessage
                                    }
                                    else {
                                        $Result.ExtractionSuccess = $false
                                        $Result.ExtractMessage = $OutputMessage
                                    }                              
                                }
                                else {
                                    If ($DownloadtoProcess.AiA){
                                        $Result_AIA.ExtractionSuccess = $true
                                    }
                                    else {
                                        $Result.ExtractionSuccess = $true
                                    }   
                                }
                            }
                            finally {
                                Pop-location
                            }  
                        }                                                               
                        else{
                            if ($DownloadtoProcess.ArchivePassword){
                                $OutputMessage = & $SevenZipFilePath "x" "-o$($DownloadtoProcess.ExtractionFolder)" "-p$($DownloadtoProcess.ArchivePassword)" "$($DownloadtoProcess.FileName)" "-y" 2>&1              
                            }
                            else {
                                $OutputMessage = & $SevenZipFilePath "x" "-o$($DownloadtoProcess.ExtractionFolder)" "$($DownloadtoProcess.FileName)" "-y" 2>&1                     
                            } 
                            if ($LASTEXITCODE -ne 0) {
                                If ($DownloadtoProcess.AiA){
                                    $Result_AIA.ExtractionSuccess = $false
                                    $Result_AIA.ExtractMessage = $OutputMessage
                                }
                                else {
                                    $Result.ExtractionSuccess = $false
                                    $Result.ExtractMessage = $OutputMessage
                                }
                            }
                            else {
                                If ($DownloadtoProcess.AiA){
                                    $Result_AIA.ExtractionSuccess = $true
                                }
                                else {
                                    $Result.ExtractionSuccess = $true
                                }                                                         
                            }                       
                        }  
                    }
                }
                $Results.Add($Result)
                if ($null -ne $Result_AIA) {
                    $Results.Add($Result_AIA)
                }                
            }
            
            Write-Output $Results   
        }        
    }

     $totalJobs = $jobs.Count
    
    Write-InformationMessage -Message "Downloading files and/or extracting where necessary" -NewLineAfter
    Write-InformationMessage -Message "Processing $totalJobs batches..."

    # Use a tracker that only INCREASES
    $maxFinished = 0
    
    while ($maxFinished -lt $totalJobs) {
       # We only count jobs that are in a terminal state
       $currentFinished = ($jobs | Where-Object { $_.State -in 'Completed', 'Failed', 'Stopped' }).Count
       
       # Only update the UI if we have made actual progress
       if ($currentFinished -gt $maxFinished) {
           $maxFinished = $currentFinished
       }

       $percentComplete = [Math]::Min(100, [int](($maxFinished / $totalJobs) * 100))
       
       Write-Progress -Activity "Processing Batches" `
                   -Status "$maxFinished / $totalJobs batches done" `
                   -PercentComplete $percentComplete

        Start-Sleep -Milliseconds 400
                   
    }
    
    Write-Progress -Activity "Processing Batches" -Completed
    
    Write-InformationMessage -Message "Processing complete" -NewLineBefore

    $results = $jobs | Receive-Job
    $jobs | Remove-Job -Force
    
    #$elapsed = $stopwatch.Elapsed

    $DebugLogFilePath = Join-PathMulti $Script:Settings.LogFolder "$((Split-Path -path $Script:Settings.LogLocation -Leaf).Split('_')[0])_ParallelRunDebugLog.txt" -UseFullPath
     
    Get-CombinedDownloadLogs -Path $ParallelRunDebugLogFolder | Out-File $DebugLogFilePath 
    

    $IsError = $false

    Write-InformationMessage -Message "Results of the download process:" -NewLineBefore -NewLineAfter

    $results.foreach({
        if ($_.DownloadStatus -eq "To Be Downloaded"){
            if ($_.DownloadSuccess -eq $false){
                Write-ErrorMessage -Message "$($_.FileName) failed to download."
                $IsError = $true
            }
            if ($_.HashCheckFailed -eq $true){
                Write-ErrorMessage -Message "$($_.FileName) failed the hash check."
                $IsError = $true
            }
        }
        if ($_.ExtractFiles -eq $true){
            if ($_.ExtractionSuccess -eq $false){
                Write-ErrorMessage -Message "There was an error extracting $($_.FileName)."
                $IsError = $true                
            }
        }
    })

    if ($IsError -eq $true){
        exit
    }
    else {
         Write-InformationMessage -Message "All files downloaded and/or extracted where applicable" 
    }
                
}          
