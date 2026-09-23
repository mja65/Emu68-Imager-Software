function Write-AmigaFilestoInterimDrive {
    param (
    )

    Write-Emu68ImagerLog -Continue
    
    $Script:Settings.CurrentTaskName = "Determining list of OS files, local install files, and files from internet to be installed"
    Write-StartTaskMessage
    
    $Script:Settings.TotalNumberofSubTasks = 3  
    
    $Script:Settings.CurrentSubTaskNumber = 1
    $Script:Settings.CurrentSubTaskName = "Performing cleanup (if applicable)"
    Write-StartSubTaskMessage
        
    # $Script:GUIActions.DeleteAllDownloadedFiles = $true
    
    if ($Script:GUIActions.DeleteAllDownloadedFiles -eq $true){
        $PathtoDelete = [System.IO.Path]::GetFullPath($($Script:Settings.WebPackagesDownloadLocation))
        Write-informationMessage -Message "Deleting existing files in $PathtoDelete"
        if (Test-Path $PathtoDelete) {
            Show-SpinnerWhileDeleting -ScriptBlock {
                $PathtoDeletetoUse = Join-Path $using:PathtoDelete "\*"
                Remove-Item $PathtoDeletetoUse -Recurse -Force -ErrorAction SilentlyContinue               
            }      
        }
    }
   
    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Identifying files to be installed"
    Write-StartSubTaskMessage

    $ListofPackagestoInstall = $(if ($Script:GUIActions.InstallOSFiles -eq $false) { Get-PackageSources -Emu68 } else { Get-PackageSources }) | sort-object { $_.PackageName }      
    $OSSources = Get-OSSources
    $OSSources_AIA = $OSSources.where({$_.SourceType -eq "ArchiveinArchive"})
    
    $ListofOSPackagestoInstall = $(if ($Script:GUIActions.InstallOSFiles -eq $true) {$OSSources}) | Select-Object SourceLocation, SourceType, ArchiveinArchiveName, ArchiveinArchivePassword, OutputLocation, CDParent -Unique
   
    $ListofOSPackagestoInstall.ForEach({
        $Line = $_
        $Line.OutputLocation = $($Script:GUIActions.FoundInstallMediatoUse).Where({$_.ADF_Name -eq $Line.SourceLocation}).Path
        $Line.ArchiveinArchiveName = $OSSources_AIA.Where({$_.SourceLocation -eq $Line.SourceLocation}).ArchiveinArchiveName 
        $Line.ArchiveinArchivePassword =  $OSSources_AIA.Where({$_.SourceLocation -eq $Line.SourceLocation}).ArchiveinArchivePassword
    })
       
    $ListofOSPackagestoInstall = $ListofOSPackagestoInstall | Select-Object SourceLocation, 
    @{
        Name = 'SourceType'
        Expression = { if ($_.SourceType -eq 'ArchiveInArchive') { 'Archive' } else { $_.SourceType } }
    }, 
    @{
        Name = 'UseLhasa'
        Expression = { if ($_.SourceType -in @('ArchiveInArchive', 'Archive'))  { 'TRUE - NOCHECK' } else {$null } }
    }, CDParent, ArchiveinArchiveName, ArchiveinArchivePassword, OutputLocation -Unique
    
        
    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Checking status of files already downloaded"
    Write-StartSubTaskMessage

    $PackagetoReport = $null
    foreach ($Line in $ListofPackagestoInstall) {       
        if ($Line.PackageName -ne $PackagetoReport) {
            $PackagetoReport = $Line.PackageName            
            Write-informationMessage -Message "Determining download details for Package(s): $PackagetoReport" -NewLineBefore           
        }                            
        if ($Line.SourceType -match "Web"){              
            $FileExists = Test-Path -Path $Line.OutputLocation
            if ((-not $FileExists) -or ($Line.AlwaysDownload -eq $true)){
                $Line.DownloadFileFlag = $true 

            }            
            elseif (($FileExists) -and ($Line.PerformHashCheck -eq $true)){
                $ValidHash = (Compare-FileHash -FiletoCheck $Line.OutputLocation -HashtoCheck $Line.Hash -RunParallel $false)
                if ($ValidHash -eq $true){
                    $Line.DownloadFileFlag = $false   
                }
                else {
                    $Line.DownloadFileFlag = $true  
                }
            }
            else {
                $Line.DownloadFileFlag = $false
            }
            if (($Line.DownloadFileFlag -eq $true) -and ($FileExists)) {
                Write-InformationMessage -Message "Deleting previously downloaded file $($line.SourceLocation) before re-downloading" -NewLineBefore
                Remove-Item -Path $Line.OutputLocation -Force -ErrorAction SilentlyContinue
            }
            If ($Line.DownloadFileFlag -eq $false){
                continue
            }
 
            switch ($Line.SourceType) {
                "Web - AminetSearch" {
                    $Line.RevisedDownloadURL = (Find-LatestAminetPackage -PackagetoFind $Line.UpdatePackageSearchTerm -Exclusion $Line.UpdatePackageSearchExclusionTerm -DateNewerthan $Line.UpdatePackageSearchMinimumDate -Architecture 'm68k-amigaos') 
                }
                "Web - Github" {
                    $Line.RevisedDownloadURL = Get-GithubRelease -GithubRepository $Line.URL -GithubReleaseType $Line.GithubReleaseType -Tag_Name $Line.GithubRelease -Name $Line.GithubName -GithubNameExclude $Line.GithubNameExclude -GithubSortTagPrefix $Line.GithubSortTagPrefix -GithubSortSemanticVersion $Line.GithubSortSemanticVersion -MinimumPublishedDate $Line.GithubMinimumPublishedDate                        
                }
                "Web - Github Emu68 Documentation" {
                    $Line.RevisedDownloadURL = Get-GithubRelease -GithubRepository $Line.URL -GithubReleaseType $Line.GithubReleaseType -Tag_Name $Line.GithubRelease -Name $Line.GithubName -GithubNameExclude $Line.GithubNameExclude -GithubSortTagPrefix $Line.GithubSortTagPrefix -GithubSortSemanticVersion $Line.GithubSortSemanticVersion -MinimumPublishedDate $Line.GithubMinimumPublishedDate    
                }
                "Web - WHDLoadWrapper"{
                    $Line.RevisedDownloadURL = (Find-WHDLoadWrapperURL -SearchCriteria 'WHDLoadWrapper' -ResultLimit '10') 
                    If (-not ($Line.RevisedDownloadURL)){
                        Write-InformationMessage -Message "Using backup location for WHDLoadWrapper"
                        $Line.RevisedDownloadURL = $Line.BackupSourceLocation            
                    }
                }
                Default{
                    $Line.RevisedDownloadURL = $Line.URL
                }                
            }                
        }
    }   
    
    # $ListofPackagestoInstall | Export-Csv -Path "test.txt" -delimiter ";" -NoTypeInformation
    Write-TaskCompleteMessage
    
    $Script:Settings.CurrentTaskName = "Downloading and extracting files"
    Write-StartTaskMessage

    if (-not (Test-Path -Path $Settings.WebPackagesDownloadLocation)){
        $null = New-Item -Path $Settings.WebPackagesDownloadLocation -ItemType Directory -ErrorAction SilentlyContinue
    } 
    
    If ($Script:GUIActions.RunParallel -eq $true) {

        Get-PackagesfromInternetParallel -ListofOSPackages ($ListofOSPackagestoInstall.where({$_.SourceType -ne "CD"})) -ListofNonOSPackages $ListofPackagestoInstall
    }
    else {
        $CombinedOSandPackages = ($ListofPackagestoInstall + $ListofOSPackagestoInstall.where({$_.SourceType -ne "CD"}))
        Get-PackagesfromInternet -ListofPackagestoDownload $CombinedOSandPackages
        
    }
        
    $PackagesNotDownloaded = @("UserFiles - Local - Archive", "Local - Files - Cmdline.txt", "Local - Files - Config.txt", "Local - Archive", "UserFiles - Local - Files", "Local - Files")
    $SkippedPackages = $ListofPackagestoInstall.where({$_.DownloadFileFlag -ne $true -and (-not ($_.SourceType -in $PackagesNotDownloaded ))})
        
    If ($SkippedPackages) {
        
        Write-InformationMessage -Message "The following files are already downloaded and were not re-downloaded:" -NewLineBefore -NewLineAfter
        
        foreach ($Line in $SkippedPackages){
            $NameofDL = (Split-Path $Line.OutputLocation -Leaf)
            Write-InformationMessage -Message "$NameofDL already downloaded."        
        }
    }

    Write-TaskCompleteMessage

    $Script:Settings.CurrentTaskName = "Copying files to interim drive"
    Write-StartTaskMessage

    $Script:Settings.TotalNumberofSubTasks = 5  

    $Script:Settings.CurrentSubTaskNumber = 1
    $Script:Settings.CurrentSubTaskName = "Creating interim drive folders"
    Write-StartSubTaskMessage

    $FAT32Partitions = (@($Script:GUICurrentStatus.GPTMBRPartitionsandBoundaries)).Partition.where({$_.PartitionSubType -eq 'FAT32'})

    $FAT32Partitions.ForEach({
        $PathtoCreate = join-path $Script:Settings.InterimAmigaDrives $_.VolumeName
        if (test-path $PathtoCreate -PathType Container){
            $null = Remove-Item $PathtoCreate -Recurse -Force
        }            
        $null = New-Item $PathtoCreate -ItemType Directory
    })
                    

    if ($Script:GUIActions.InstallOSFiles -eq $true){
        if (-not ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries)){
            $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -Amiga)
        }  
        $RDBPartitions = @($Script:GUICurrentStatus.AmigaPartitionsandBoundaries).Partition
        $RDBPartitions.ForEach({
            $VolumeNametoUse = if ($_.VolumeName -eq "Workbench") {"System"} else { $_.VolumeName }
            $PathtoCreate = join-path $Script:Settings.InterimAmigaDrives $VolumeNametoUse
            if (test-path $PathtoCreate -PathType Container){
                $null = Remove-Item $PathtoCreate -Recurse -Force
            }            
            $null = New-Item $PathtoCreate -ItemType Directory
        })       
    }
    
    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Identifying files to copy"
    Write-StartSubTaskMessage
    
    $ValidPackages = $ListofPackagestoInstall | ForEach-Object { ($_.PackageName -split ",").Trim() } | Select-Object -Unique
    $PackageFilestoInstall = (Get-InputFileCSV -CSV "PackagestoInstall").where({ $_.PackageName.Trim() -in $ValidPackages }) 
    
    $ValidOSPackages = @((($OSSources | select-object PackageName).PackageName -split ",").Trim() | Select-Object  -Unique)
    $OSFilestoInstall = (Get-InputFileCSV -CSV "OSFilestoInstall").where({ $_.PackageName -in $ValidOSPackages }) 

    $CreatedDirectories = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    $OSPathLookup = @{}

    $($Script:GUIActions.FoundInstallMediatoUse).ForEach({
        $OSPathLookup[$_.ADF_Name] = [PSCustomObject]@{
            InstallMedia = $_.InstallMedia
            FileName = [System.IO.Path]::GetFileNameWithoutExtension($_.Path)
            FullPath = $_.Path
        }   
    })
    
    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Copying OS files to interim drive"
    Write-StartSubTaskMessage

    if ($Script:GUIActions.KickstartVersiontoUse -eq 3.9) {
   
        Write-InformationMessage -Message "Extracting and copying files from .iso file"

        $CDFileExtractionMap = [System.Collections.Generic.List[PSCustomObject]]::new()
        #foreach ($Line in ($OSFilestoInstall.where({$_.SourcePath -eq "OS-Version3.9\Workbench3.5\Storage\DOSDrivers\PC0.info"})) ){
        foreach ($Line in ($OSFilestoInstall) ){            
            $InstallMediaType = $OSPathLookup[$Line.SourceLocation].InstallMedia
            if ($InstallMediaType -eq "CD"){            
                $FullPath = $OSPathLookup[$Line.SourceLocation].FullPath
                $DestinationPath = join-pathMulti $Script:Settings.InterimAmigaDrives $Line.DrivetoInstall $Line.DestinationPath -UseFullPath 
                $CDFileExtractionMap.Add([PSCustomObject]@{
                    FullPath = $FullPath 
                    SourcePath = $Line.SourcePath 
                    DestinationPath = $DestinationPath
                }) 
            }
            $DestinationFolder = [System.IO.Path]::GetDirectoryName($DestinationPath)
            if (-not $CreatedDirectories.Contains($DestinationFolder)) {                
                $null = [System.IO.Directory]::CreateDirectory($DestinationFolder)
                $null = $CreatedDirectories.Add($DestinationFolder)            
            }
        }
    
        $CDGroupedFiles = $CDFileExtractionMap | Group-Object -Property FullPath
    
        foreach ($IsoGroup in $CDGroupedFiles) {
            $IsoPath = $IsoGroup.Name
            $GroupedFiles   = $IsoGroup.Group
        
            [string[]]$SourcePathList = $GroupedFiles | ForEach-Object { [string]$_.SourcePath }
            [string[]]$DestinationPathList   = $GroupedFiles | ForEach-Object { [string]$_.DestinationPath }
        
            [ISOExtractor]::ExtractExplicitFiles($IsoPath, $SourcePathList, $DestinationPathList)
        } 

    }
        
    $ZFileNameCounter = 1

    $ZFileStagingFolder = join-pathMulti $Script:Settings.TempFolder "ZFileStaging" -UseFullPath

    If (Test-Path $ZFileStagingFolder){
        $null = Remove-Item $ZFileStagingFolder -Recurse -Force
    }
    $null = New-Item $ZFileStagingFolder -ItemType Directory
    
    $ZfileLookupTable = [System.Collections.Generic.List[PSCustomObject]]::new()
   
    #foreach ($Line in ($OSFilestoInstall.where({$_.DecompressFile -eq "True"})) ){

    $SortedOSFiles = $OSFilestoInstall | Sort-Object -Property { $OSPathLookup[$_.SourceLocation].InstallOrder }

    foreach ($Line in $SortedOSFiles){
        $SourceInfo = $OSPathLookup[$Line.SourceLocation]
        $InstallMediaType = $SourceInfo.InstallMedia
        $InstallOrder = $SourceInfo.InstallOrder
        if ($InstallMediaType -eq "CD") { continue }
        $FileName = $SourceInfo.FileName
        If ($InstallMediaType -eq "Archive"){
            $SourcePath = join-pathMulti $Script:Settings.WebPackagesDownloadLocation $FileName $Line.SourcePath -UseFullPath -ExtendedPrefix                 
        }
        # elseif ($InstallMediaType -eq "CD"){
        #     $SourcePath = join-pathMulti $Script:Settings.CDTemporaryFiles $Line.SourceLocation $Line.SourcePath -UseFullPath -ExtendedPrefix         
        # }
        elseif ($InstallMediaType -eq "Disk"){
            #Write-Host "ADFTemporaryFilesPath is: $($Script:Settings.ADFTemporaryFiles) SourceLocation is: $($Line.SourceLocation) SourcePath is: $($Line.SourcePath)"
            $SourcePath = join-pathMulti $Script:Settings.ADFTemporaryFiles $Line.SourceLocation $Line.SourcePath -UseFullPath -ExtendedPrefix  
        }
        $DestinationPath = join-pathMulti $Script:Settings.InterimAmigaDrives $Line.DrivetoInstall $Line.DestinationPath -UseFullPath -ExtendedPrefix
        $DestinationFolder = [System.IO.Path]::GetDirectoryName($DestinationPath)
        if (-not $CreatedDirectories.Contains($DestinationFolder)) {
            $null = [System.IO.Directory]::CreateDirectory($DestinationFolder)
            $null = $CreatedDirectories.Add($DestinationFolder)            
        }
        If ($Line.DecompressFile -eq "TRUE"){
            $StagingFileName = "ZFile_$($ZFileNameCounter)"
            $StagingZFileName = "$StagingFileName.Z"
            $StagingDestinationPath = join-pathMulti $ZFileStagingFolder $StagingZFileName
            $ExtractedZFileSourcePath = join-pathMulti $ZFileStagingFolder $StagingFileName
            $ZfileLookupTable.Add([PSCustomObject]@{
                ExtractedZFileSourcePath = $ExtractedZFileSourcePath
                DestinationPath = $DestinationPath
            })
            [System.IO.File]::Copy($SourcePath, $StagingDestinationPath, $true)
            $ZFileNameCounter ++
        }
        else {
            #Write-host "SourcePath is: $SourcePath DestinationPath is: $DestinationPath"
            [System.IO.File]::Copy($SourcePath, $DestinationPath, $true)
        }
        If ($Line.ProtectionBits){
            $FileName = [System.IO.Path]::GetFileName($DestinationPath)
            $ProtectionBits = $Line.ProtectionBits.ToUpper()
            $H = if ($ProtectionBits.Contains('H')) { 'H' } else { '-' }
            $S = if ($ProtectionBits.Contains('S')) { 'S' } else { '-' }
            $P = if ($ProtectionBits.Contains('P')) { 'P' } else { '-' }
            $A = if ($ProtectionBits.Contains('A')) { 'A' } else { '-' }
            $R = if ($ProtectionBits.Contains('R')) { 'R' } else { '-' }
            $W = if ($ProtectionBits.Contains('W')) { 'W' } else { '-' }
            $E = if ($ProtectionBits.Contains('E')) { 'E' } else { '-' }
            $D = if ($ProtectionBits.Contains('D')) { 'D' } else { '-' }
            $ProtectionString = "$H$S$P$A$R$W$E$D"
            $RawHex = Get-UAEFSDB -Flags $ProtectionString -AmigaName $FileName -NormalName $FileName -Comment ""
            Write-informationMessage -Message "Updating protection bits for $Filename"                        
            Update-UAEFSDB -Path $DestinationPath -UAEFSEntry $RawHex                              
        }               
    }
        
    If ($ZfileLookupTable){

        Write-InformationMessage -Message ".Z Files detected! Extracting .Z Files to temporary folder" -NewLineBefore

        $SevenZipFilePathFull = [System.IO.Path]::GetFullPath($Script:ExternalProgramSettings.SevenZipFilePath)
 
        Push-Location -Path $ZFileStagingFolder
 
        $OutputMessage = & $SevenZipFilePathFull "x" "*.z" "-y" 2>&1
 
        Pop-location

        Write-InformationMessage -Message "Copying extracted .Z Files to interim drive"

        foreach ($ZFile in $ZfileLookupTable){
            $SourcePath = $ZFile.ExtractedZFileSourcePath
            $DestinationPath = $ZFile.DestinationPath
            $DestinationFolder = [System.IO.Path]::GetDirectoryName($DestinationPath)
            #Write-host "SourcePath is: $SourcePath DestinationPath is: $DestinationPath"
            if (-not $CreatedDirectories.Contains($DestinationFolder)) {
                $null = [System.IO.Directory]::CreateDirectory($DestinationFolder)
                $null = $CreatedDirectories.Add($DestinationFolder)            
            }
            [System.IO.File]::Copy($SourcePath, $DestinationPath, $true)
        }

    }

    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Copying Kickstart ROMS to FAT32 Interim Drive and Devs/Kickstarts"
    Write-StartSubTaskMessage
    
    $RomstoCopy = $Script:GUIActions.FoundKickstarttoUse.where({$_.Status -eq "Found"})

    foreach ($ROM in $RomstoCopy){
        $SourcePath = $Rom.KickstartPath
        if ($Rom.KickstartVersion){
            $DestinationPath =  Join-PathMulti $Script:Settings.InterimAmigaDrives "Emu68Boot" $ROM.Fat32Name
            $DestinationFolder = [System.IO.Path]::GetDirectoryName($DestinationPath)
            # Write-debug $DestinationFolder 
            if (-not $CreatedDirectories.Contains($DestinationFolder)) {
                $null = [System.IO.Directory]::CreateDirectory($DestinationFolder)
                $null = $CreatedDirectories.Add($DestinationFolder)            
            }             
            [System.IO.File]::Copy($SourcePath, $DestinationPath, $true)  
       
        }
        if (($Script:GUIActions.InstallOSFiles -eq $true) -and (-not [string]::IsNullOrWhiteSpace($ROM.WHDLoadName))){
            $DestinationPath = Join-PathMulti $Script:Settings.InterimAmigaDrives "System" "Devs" "Kickstarts" $Rom.WhdLoadName
            $DestinationFolder = [System.IO.Path]::GetDirectoryName($DestinationPath)
            if (-not $CreatedDirectories.Contains($DestinationFolder)) {
                #Write-host $DestinationFolder
                $null = [System.IO.Directory]::CreateDirectory($DestinationFolder)
                $null = $CreatedDirectories.Add($DestinationFolder)            
            }
            #Write-host "SourcePath is: $SourcePath DestinationPath is: $DestinationPath"
            [System.IO.File]::Copy($SourcePath, $DestinationPath, $true)                  
       }
    }    

    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Copying Package files to interim drive"
    Write-StartSubTaskMessage
       
    foreach ($line in $PackageFilestoInstall) {
    #  foreach ($line in ($PackageFilestoInstall | Where-Object {$_.SourceType -in @('Web - Github Emu68 Documentation')})  ) {
    #foreach ($line in ($PackageFilestoInstall.Where({($_.PackageName -eq "Roadshow - Full")}))) {
        If ($Line.PackageName -eq "Roadshow - Full"){
            $ExtractedFileFolder = [System.IO.Path]::GetFileNameWithoutExtension($Script:GUICurrentStatus.RoadshowUserFiles.ArchiveName) 
        }
        else {
            $ExtractedFileFolder = [System.IO.Path]::GetFileNameWithoutExtension($Line.SourceLocation) 
        }
        Switch ($line.SourceType) {
            { $_ -in 'Local - Files' } {
                $BaseFolder = $Script:Settings.LocationofAmigaFiles
            }
            { $_ -in 'Local - Files - Config.txt', 'Local - Files - Cmdline.txt' } {
                $BaseFolder = $Script:Settings.Emu68ImagerSupportingFiles
            }            
            { $_ -in "UserFiles - Local - Files"} {
                If ($_.PackageName -eq "Miami - Full"){
                    $BaseFolder = $Script:GUICurrentStatus.MiamiUserFiles
                }
                else {
                    Write-ErrorMessage -Message "Not Built!"
                }
            }
            {$_ -eq 'Web - Github'}{
                if ([System.IO.Path]::GetExtension($Line.SourceLocation) -notin @('.lha','.zip','.lzx')){
                    $BaseFolder = $Script:Settings.WebPackagesDownloadLocation
                }
                else {
                    $BaseFolder = join-path $Script:Settings.WebPackagesDownloadLocation $ExtractedFileFolder
                }
            }
            default {

                $BaseFolder = join-path $Script:Settings.WebPackagesDownloadLocation $ExtractedFileFolder
            }
        }
                                      
        $ItemstoCopy = @()
        if ($line.SourcePath.Contains('*')) {
            $CombinedWildcard = join-pathMulti $BaseFolder $line.SourcePath
            $Matches = @(Get-ChildItem -Path $CombinedWildcard -ErrorAction SilentlyContinue)
            foreach ($match in $Matches) {
                $ItemstoCopy += [PSCustomObject]@{
                    Source      = $match.FullName
                    ProtectionBits = $Line.ProtectionBits
                    Destination = if ($line.DestinationPath.Contains('*')) {
                                    Join-pathMulti $Script:Settings.InterimAmigaDrives $line.DrivetoInstall $line.LocationtoInstall $match.name -UseFullPath -ExtendedPrefix 
                                }
                                else {
                                    Join-pathMulti $Script:Settings.InterimAmigaDrives $line.DrivetoInstall $Line.DestinationPath -UseFullPath -ExtendedPrefix                                    
                                }
                }
            }
        }
        else {
            If ($Line.ArchiveinArchiveName){
                $SourcePath =  join-pathMulti $BaseFolder "AiA" $Line.SourcePath  -UseFullPath -ExtendedPrefix   
            }
            else {
                $SourcePath =  join-pathMulti $BaseFolder $Line.SourcePath -UseFullPath -ExtendedPrefix   
            }
            $ItemstoCopy += [PSCustomObject]@{
                Source  = $SourcePath 
                ProtectionBits = $Line.ProtectionBits
                Destination = Join-pathMulti $Script:Settings.InterimAmigaDrives $Line.DrivetoInstall $Line.DestinationPath -UseFullPath -ExtendedPrefix   
            }
        }
        
        foreach ($Item in $ItemstoCopy ) {
            #Write-host "SourcePath is: $($Item.Source) DestinationPath is: $($Item.Destination)"
            $DestinationFolder = [System.IO.Path]::GetDirectoryName($Item.Destination)
            if (-not $CreatedDirectories.Contains($DestinationFolder)) {
                #Write-Host $DestinationFolder
                $null = [System.IO.Directory]::CreateDirectory($DestinationFolder)
                $null = $CreatedDirectories.Add($DestinationFolder)            
            }

            switch ($Line.SourceType) {
                'Local - Files - Config.txt'{
                    Write-InformationMessage -Message "Preparing Config.txt" 
                    if ($Script:GUIActions.EnableBupTest -eq $true -and $Script:GUIActions.Emu68VersionType -ne "Release"){
                        $UpdatedConfig = Get-ConfigTXT -PathtoConfigTXT $Item.Source
                        $UpdatedConfigNoBUPTEST = Get-ConfigTXT -PathtoConfigTXT $Item.Source -NoBuptest
                        Export-TextFile -PC -DatatoExport $UpdatedConfigNoBUPTEST -ExportFile "$($Item.Destination).BAK" -AddLineFeeds
                    }                   
                    else {
                        $UpdatedConfig = Get-ConfigTXT -PathtoConfigTXT $Item.Source -NoBuptest
                        #$UpdatedConfig = Get-ConfigTXT "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Assets\AmigaFiles\EMU68Boot\config11.txt" -NoBuptest
                    }
                    Export-TextFile -PC -DatatoExport $UpdatedConfig -ExportFile $Item.Destination -AddLineFeeds
                    # Export-TextFile -PC -DatatoExport $UpdatedConfig -ExportFile "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\InterimAmigaDrives\EMU68BOOT\config2.txt" -AddLineFeeds
                }
                'Local - Files - Cmdline.txt'{
                    Write-InformationMessage -Message "Preparing Cmdline.txt" 
                    if ($Script:GUIActions.EnableBupTest -eq $true){
                        Update-CmdlineTXT -PathtoCmdlineTXT $Item.Source -PathtoExportedCmdlineTXT $Item.Destination
                        Update-CmdlineTXT -PathtoCmdlineTXT $Item.Source -PathtoExportedCmdlineTXT "$($Item.Destination).BAK" -NoBuptest                
                    }
                    else {
                        Update-CmdlineTXT -PathtoCmdlineTXT $Item.Source -PathtoExportedCmdlineTXT $Item.Destination -NoBuptest   
                    }
                }
                'Web - Github Emu68 Documentation'{
                    [System.IO.File]::Copy($Item.Source, $Item.Destination, $true)
                    if ([System.IO.Path]::GetExtension($Item.Destination) -eq ".html"){
                        Update-Emu68ImagerDocumentation -Emu68ImagerDocumentationPath $Item.Destination                   
                    }
                }
                default {
                    [System.IO.File]::Copy($Item.Source, $Item.Destination, $true)
                    If ($Item.ProtectionBits){
                        $FileName = [System.IO.Path]::GetFileName($Item.Destination)
                        $ProtectionBits = $Item.ProtectionBits.ToUpper()
                        $H = if ($ProtectionBits.Contains('H')) { 'H' } else { '-' }
                        $S = if ($ProtectionBits.Contains('S')) { 'S' } else { '-' }
                        $P = if ($ProtectionBits.Contains('P')) { 'P' } else { '-' }
                        $A = if ($ProtectionBits.Contains('A')) { 'A' } else { '-' }
                        $R = if ($ProtectionBits.Contains('R')) { 'R' } else { '-' }
                        $W = if ($ProtectionBits.Contains('W')) { 'W' } else { '-' }
                        $E = if ($ProtectionBits.Contains('E')) { 'E' } else { '-' }
                        $D = if ($ProtectionBits.Contains('D')) { 'D' } else { '-' }
                        $ProtectionString = "$H$S$P$A$R$W$E$D"
                        $RawHex = Get-UAEFSDB -Flags $ProtectionString -AmigaName $FileName -NormalName $FileName -Comment ""
                        Write-informationMessage -Message "Updating protection bits for $Filename"                        
                        Update-UAEFSDB -Path $Item.Destination -UAEFSEntry $RawHex                              
                    }                
                }
            }
            

            
        }
    }
                     
    Write-TaskCompleteMessage

    if ($Script:GUIActions.InstallOSFiles -eq $false) {
        return
    }
 
            
    $Script:Settings.CurrentTaskName = "Peforming additional installation steps"
    Write-StartTaskMessage
    
    $Script:Settings.TotalNumberofSubTasks = 5
        
    $Script:Settings.CurrentSubTaskNumber = 1
    $Script:Settings.CurrentSubTaskName = "Modifying scripts"
    Write-StartSubTaskMessage
        
    $ListofScriptstoChange = (Get-InputFileCSV -CSV "ScriptModify").where({ $_.PackageName.Trim() -in ($ValidPackages + $ValidOSPackages) }) | Sort-Object -Property InstallOrder
    
    $ListofScriptstoChange | ForEach-Object { 
        $ScripttoModifyPath = Join-PathMulti $Script:Settings.InterimAmigaDrives "System" $_.ModifyScript
        if (-not (Test-Path $ScripttoModifyPath)){
            [System.IO.File]::WriteAllText($ScripttoModifyPath,'',[System.Text.Encoding]::GetEncoding('iso-8859-1'))
        }
        $ScriptPathtoChanges = join-pathMulti $Script:Settings.Emu68ImagerSupportingFiles "System" $_.ScriptPathtoChanges 
        if ($_.ScriptArexxFlag -eq 'True'){
            Update-AmigaScripts -ScripttoModifyPath $ScripttoModifyPath `
                                -ScriptPathtoChanges $ScriptPathtoChanges `
                                -ScriptEditStartPoint $_.ScriptEditStartPoint `
                                -ScriptEditEndPoint $_.ScriptEditEndPoint `
                                -NameofChange $_.ScriptNameofChange `
                                -Action $_.ModifyScriptAction `
                                -AREXXFlag
        }
        else {
            Update-AmigaScripts -ScripttoModifyPath $ScripttoModifyPath `
                                -ScriptPathtoChanges $ScriptPathtoChanges `
                                -ScriptEditStartPoint $_.ScriptEditStartPoint `
                                -ScriptEditEndPoint $_.ScriptEditEndPoint `
                                -NameofChange $_.ScriptNameofChange `
                                -Action $_.ModifyScriptAction
        }
    }
  
    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Modifying file paths for scripts"
    Write-StartSubTaskMessage

    $ListofScriptstoModifyFilePath =  @(Get-InputFileCSV -CSV "FileContentsModifyPath").where({ $_.PackageName.Trim() -in ($ValidPackages + $ValidOSPackages) })
    
    $ListofScriptstoModifyFilePath | ForEach-Object {
        if ($_.SourceType -eq "Local - Files"){
            $File = Join-PathMulti $Script:Settings.Emu68ImagerSupportingFiles $_.SourcePath -UseFullPath
        }
        else {
            Write-ErrorMessage "Not built!"
            Exit
        }
        $DestinationPath =  join-pathMulti $Script:Settings.InterimAmigaDrives $_.RevisedDrive $_.DestinationPath -UseFullPath
        $DestinationFolder = split-path -Path $DestinationPath -Parent
        $Drive = if ($_.RevisedDrive -eq "System") { "SYS:" } else { "$($_.RevisedDrive):" }
        $RevisedPath = $_.RevisedPath.replace("\","/").TrimEnd('/\')
        $FullPath = if ([string]::IsNullOrWhiteSpace($RevisedPath)) { $Drive } else { "$Drive$RevisedPath" }
        $RevisedContent = Update-FileWithInstallPath -File $File -RevisedPath  $FullPath 
         
        
        if (-not (Test-Path -path $DestinationFolder -PathType Container)) {
            $null = New-Item -Path $DestinationFolder -ItemType Directory -Force
        } 
        Export-TextFile -Amiga -ExportFile $DestinationPath -DatatoExport $RevisedContent -AddLineFeeds         
    }
    
    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Modifying icons and infotypes"
    Write-StartSubTaskMessage

    $DiskIconstoAddFAT32 = $FAT32Partitions | Select-Object @{
        Name = 'IconType'
        Expression = { if ($_.DefaultGPTMBRPartition -eq $true) { "Emu68BootDisk" } else { "Emu68BootDisk" } }
    }, VolumeName
   

    $DiskIconstoAddAmiga = $RDBPartitions | Select-Object @{
        Name = 'IconType'
        Expression = { if ($_.DefaultAmigaWorkbenchPartition -eq $true) { "SystemDisk" } else { "WorkDisk" } }
    }, VolumeName

    $FolderIconsToAdd = @(
        [pscustomobject]@{
            IconType   = 'NewFolder'
            VolumeName = 'NewFolder'
        }
    )
    
    $CombinedDiskIconstoAdd = @(
        if ($null -ne $DiskIconstoAddFAT32) { $DiskIconstoAddFAT32 }
        if ($null -ne $DiskIconstoAddAmiga) { $DiskIconstoAddAmiga }
        if ($null -ne $FolderIconsToAdd) { $FolderIconsToAdd }
    )

    $IconsPathHash = @{}

    $IconTempDestinationPath = Join-pathMulti $Script:Settings.TempFolder "IconFiles" -UseFullPath 

    if (Test-Path -Path $IconTempDestinationPath -PathType Container){
        Remove-Item -Path  $IconTempDestinationPath -Force -recurse -ErrorAction SilentlyContinue
    }
    $null = New-Item $IconTempDestinationPath -ItemType Directory -Force

    
    (Get-IconPaths).foreach({
        $IconsPathHash[$_.IconType] = [PSCustomObject]@{  
            Source  =  $_.Source
            SourceLocation =  $_.SourceLocation   
            InstallMedia  =  $_.InstallMedia   
            FilestoInstall =  $_.FilestoInstall  
            ModifyInfoFileType =$_.ModifyInfoFileType
            NewFileNameFlag  = $_.NewFileNameFlag
            InstallMediaPath  = $_.InstallMediaPath
            NewFileName =    $_.NewFileName
            
        } 
    })
    
    $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.UpdateDefaultIcons = [System.Collections.Generic.List[PSCustomObject]]::New()

    $CDFileExtractionMap = [System.Collections.Generic.List[PSCustomObject]]::new()

    $CombinedDiskIconstoAdd.ForEach({
        $InstallMediaType = $IconsPathHash[$_.IconType].InstallMedia
        $IconType = $_.IconType
        $VolumeNametoUse = if ($_.VolumeName -eq "Workbench") {"System"} else { $_.VolumeName }
        $FilestoInstall = $IconsPathHash[$_.IconType].FilestoInstall
        $OldFileName = Split-Path $FilestoInstall -Leaf
        $NewFileName = $IconsPathHash[$_.IconType].NewFileName
        $FileName = $(if ($NewFileName) {$NewFileName} else { $OldFileName }).ToLower()
        $Source = $IconsPathHash[$_.IconType].Source
        $SourcePathtoUse = $(
            if ($InstallMediaType -eq "ADF") { 
                Join-PathMulti $Script:Settings.ADFTemporaryFiles $Source $FilestoInstall -UseFullPath 
            } 
            elseif ($InstallMediaType -eq "CD") {
                Join-PathMulti $FilestoInstall
            }
            else {
                "ERROR" 
            }
        )
        If ($IconType -eq "NewFolder"){
            $DestinationPathFolder = Join-pathMulti $Script:Settings.TempFolder "IconFiles" -UseFullPath 
            if (Test-Path -Path $DestinationPathFolder -PathType Container){
                Remove-Item -Path  $DestinationPathFolder -Force -recurse -ErrorAction SilentlyContinue
            }
            $null = New-Item $DestinationPathFolder -ItemType Directory -Force
            $DestinationPathToUse = Join-PathMulti $DestinationPathFolder $FileName

        }
        else {
            $DestinationPathToUse = Join-PathMulti $Script:Settings.InterimAmigaDrives $VolumeNametoUse $FileName -UseFullPath
        }
        if ($InstallMediaType -eq "CD"){
            $CDFileExtractionMap.Add([PSCustomObject]@{
                FullPath = $IconsPathHash[$_.IconType].InstallMediaPath
                SourcePath = $SourcePathtoUse
                DestinationPath = $DestinationPathToUse
            })             
        }
        else {
            #Write-host "Source: $SourcePathtoUse Destination: $DestinationPathToUse"
            $null = Copy-Item $SourcePathtoUse $DestinationPathToUse -Force -Recurse 
        }
        If ($IconsPathHash[$_.IconType].ModifyInfoFileType){
            $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.UpdateDefaultIcons.Add([PSCustomObject]@{
                Command =  (Get-ToolTypeCommands -FilePath $DestinationPathToUse -Type $($IconsPathHash[$_.IconType].ModifyInfoFileType)) 
                Sequence = 1

           })

        }
    })

    if ($CDFileExtractionMap) {
        $CDGroupedFiles = $CDFileExtractionMap | Group-Object -Property FullPath
        foreach ($IsoGroup in $CDGroupedFiles) {
            $IsoPath = $IsoGroup.Name
            $GroupedFiles   = $IsoGroup.Group
            [string[]]$SourcePathList = $GroupedFiles | ForEach-Object { [string]$_.SourcePath }
            [string[]]$DestinationPathList   = $GroupedFiles | ForEach-Object { [string]$_.DestinationPath }
            [ISOExtractor]::ExtractExplicitFiles($IsoPath, $SourcePathList, $DestinationPathList)
        }
    }

    $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.AdjustIcons = [System.Collections.Generic.List[PSCustomObject]]::New()

    $DiskIconPositions = Get-DiskIconPositions -ListofDisks ($CombinedDiskIconstoAdd.VolumeName).where({$_ -ne "NewFolder"})
    $IconPositions = @(Get-InputFileCSV -CSV 'IconPositions')

    $IconPositions.foreach({
        $FilePath = join-pathmulti $Script:Settings.InterimAmigaDrives $_.Drive $_.file.replace("/","\") -UseFullPath
        if (Test-path -Path $FilePath){
            $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.AdjustIcons.Add([PSCustomObject]@{
                Command = (Get-ToolTypeCommands -FilePath $FilePath -Type $_.type -IconX $_.IconX -IconY $_.IconY -DrawerX $_.DrawerX -DrawerY $_.DrawerY -DrawerWidth $_.DrawerWidth -DrawerHeight $_.DrawerHeight)
                Sequence = 1
            })
        }   
    })

    $DiskIconPositions.foreach({
        $Drive = if ($_.Volume -eq "Workbench") {"System"} else {$_.Volume }
        $FilePath = join-pathmulti $Script:Settings.InterimAmigaDrives $Drive "Disk.info" -UseFullPath
        $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.AdjustIcons.Add([PSCustomObject]@{
           Command =  (Get-ToolTypeCommands -FilePath $FilePath -type "Disk" -IconX $_.IconX -IconY $_.IconY -DrawerX $_.DrawerX -DrawerY $_.DrawerY -DrawerWidth $_.DWidth -DrawerHeight $_.DHeight)
           Sequence = 2
        })
    })

    $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.ModifyToolTypes = [System.Collections.Generic.List[PSCustomObject]]::New()

    $InfoFilestoAdjust = @(Get-InputFileCSV 'InfoFiles').where({  $_.PackageName.Trim() -in ($ValidPackages + $ValidOSPackages) }) 
    
    foreach ($InfoFileLine in $InfoFilestoAdjust){
        $PathtoIcon = Join-PathMulti $Script:Settings.InterimAmigaDrives $InfoFileLine.DrivetoInstall $InfoFileLine.DestinationPath -UseFullPath
        if ($InfoFileLine.ModifyInfoFileType -ne 'False'){
            $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.ModifyToolTypes.Add([PSCustomObject]@{
                Command = (Get-ToolTypeCommands -FilePath $PathtoIcon -Type $InfoFileLine.ModifyInfoFileType)
                Sequence = 1
            })
        }
        if ($InfoFileLine.ModifyInfoFileTooltype -eq 'Modify'){
            $FolderforExportedInfoTypes = Join-path $Script:Settings.TempFolder "ChangedInfoFiles"
            $ExportToolTypesPath = Join-pathMulti $FolderforExportedInfoTypes "$($InfoFileLine.Filename).txt" -UseFullPath 
            if (-not (Test-Path -Path $FolderforExportedInfoTypes -PathType Container)){
                $null = New-Item -Path $FolderforExportedInfoTypes -ItemType Directory
            }
            $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.ModifyToolTypes.Add([PSCustomObject]@{
                Command = "icon tooltypes export `"$PathtoIcon`" `"$ExportToolTypesPath`""
                Sequence = 1
            })
        }
    } 
    
    Write-InformationMessage -Message "Running HST Amiga to adjust .info files - Part 1"
    
    Start-HSTAmigaCommands -HSTScript ($Script:GUICurrentStatus.HSTAmigaCommandstoProcess.UpdateDefaultIcons + $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.AdjustIcons + $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.ModifyToolTypes)

    $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.ReplaceToolTypes = [System.Collections.Generic.List[PSCustomObject]]::New()
        
   foreach ($InfoFileLine in $InfoFilestoAdjust){          
       $FolderforExportedInfoTypes = Join-path $Script:Settings.TempFolder "ChangedInfoFiles"
       $ExportToolTypesPath = Join-pathMulti $FolderforExportedInfoTypes "$($InfoFileLine.Filename).txt" -UseFullPath
       $NewOrModifiedToolTypesPath = join-pathMulti $Script:Settings.Emu68ImagerSupportingFiles $InfoFileLine.PathtoRevisedToolTypeInfo -UseFullPath      
       $NewOrModifiedToolTypes = Import-Csv $NewOrModifiedToolTypesPath -Delimiter ';'
       $AmendedToolTypePath = Join-PathMulti $Script:Settings.TempFolder "ChangedInfoFiles" "$($InfoFileLine.Filename)amendedtoimport.txt" -UseFullPath
       $PathtoIcon = Join-PathMulti $Script:Settings.InterimAmigaDrives $InfoFileLine.DrivetoInstall $InfoFileLine.DestinationPath -UseFullPath
       if ($InfoFileLine.ModifyInfoFileTooltype -eq 'Replace'){
           $NewOrModifiedToolTypes.NewValue | Out-File $AmendedToolTypePath           
       }
       elseif ($InfoFileLine.ModifyInfoFileTooltype -eq 'Modify'){
           $OldToolTypes = Get-Content $ExportToolTypesPath
           Get-ModifiedToolTypes -OriginalToolTypes $OldToolTypes -ModifiedToolTypes $NewOrModifiedToolTypes | Out-File $AmendedToolTypePath
       }
       $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.ReplaceToolTypes.Add([PSCustomObject]@{
           Command = "icon tooltypes import `"$PathtoIcon`" `"$AmendedToolTypePath`""
           Sequence = 1
       })
    }
    
    Write-InformationMessage -Message "Running HST Amiga to adjust .info files - Part 2"
    
    Start-HSTAmigaCommands -HSTScript $Script:GUICurrentStatus.HSTAmigaCommandstoProcess.ReplaceToolTypes

    Write-InformationMessage -Message "Creating IconClean OneTimeRun script"

    $RDBPartitions = @($Script:GUICurrentStatus.AmigaPartitionsandBoundaries).Partition
    $IconCleanScript = @()
    $DestinationPath = join-pathMulti $Script:Settings.InterimAmigaDrives "System" "S" "OneTimeRunWB" "IconClean"
    
    
    $RDBPartitions.ForEach({
        $VolumeNametoUse = if ($_.VolumeName -eq "Workbench") {"Sys"} else { $_.VolumeName }
        #$IconCleanScript += "C:iconclean $($VolumeNametoUse): -r sort name RESIZE CENTRE >$($VolumeNametoUse):Log.txt"
        $IconCleanScript += "C:iconclean $($VolumeNametoUse): -r sort name RESIZE CENTRE QUIET" 
    })    
    
    $IconCleanScript += "c:iconpos >NIL: Sys:WBStartup/Disabled.info XPOS=13 YPOS=222 DWIDTH=244 DHEIGHT=235"
    $IconCleanScript += "C:iconclean SYS:WBSstartup/Disabled -r sort name CENTRE QUIET"
    $IconCleanScript += "c:iconpos >NIL: Sys:WBStartup.info XPOS=13 YPOS=222 DWIDTH=244 DHEIGHT=235"
    Export-TextFile -Amiga -ExportFile $DestinationPath -DatatoExport $IconCleanScript -AddLineFeeds  

    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Setting Workbench environment"
    Write-StartSubTaskMessage

    Write-InformationMessage  "Setting WBConfig.prefs"

    $WBConfigPrefsFile = join-pathMulti $Script:Settings.InterimAmigaDrives "System" "Prefs" "Env-Archive" "Sys" "WBConfig.prefs"
    $WBConfigPrefsFileBackup = "$WBConfigPrefsFile.BAK"
    $null = Copy-Item -Path $WBConfigPrefsFile -Destination $WBConfigPrefsFileBackup 

    if ($Script:GUIActions.WorkbenchBackDropEnabled -eq $true) {
        $WBConfigPrefsToWrite = Get-BackdropPrefs -SourcePath $WBConfigPrefsFileBackup -BackdropTRUE 
    } 
    elseif ($Script:GUIActions.WorkbenchBackDropEnabled -eq $false){
        $WBConfigPrefsToWrite = Get-BackdropPrefs -SourcePath $WBConfigPrefsFileBackup -BackdropFALSE
    }
    [System.IO.File]::WriteAllBytes($WBConfigPrefsFile, $WBConfigPrefsToWrite)

    write-informationMessage -Message "Setting ScreenMode.prefs"
    
    $ScreenModePrefsFile = join-pathMulti $Script:Settings.InterimAmigaDrives "System" "Prefs" "Env-Archive" "Sys" "ScreenMode.prefs" -UseFullPath
    $ScreenModePrefsFileUser = "$ScreenModePrefsFile.User"

    $null = Copy-Item -Path $ScreenModePrefsFile -Destination $ScreenModePrefsFileUser
    
    $ScreenModePrefsToWrite = Get-ScreenModePrefs -SourcePath $ScreenModePrefsFile -ScreenMode $Script:GUIActions.ScreenModetoUseWB -ColourDepth $Script:GUIActions.ScreenModeWBColourDepth 
    [System.IO.File]::WriteAllBytes($ScreenModePrefsFileUser, $ScreenModePrefsToWrite)
    
    if ($Script:GUIActions.ScreenModeType -eq "RTG"){
        $UAEScreenmodetoUse = $Script:GUIActions.AvailableScreenModesWB.where({ $_.FriendlyName -eq $Script:GUIActions.ScreenModetoUseWB }).UAERTGMode
        $ScreenModePrefsFileUAE = "$ScreenModePrefsFile.UAE"
        $null = Copy-Item -Path $ScreenModePrefsFile -Destination $ScreenModePrefsFileUAE
        $ScreenModePrefsToWrite = Get-ScreenModePrefs -SourcePath $ScreenModePrefsFileUAE -ModeID $UAEScreenmodetoUse -ColourDepth $Script:GUIActions.ScreenModeWBColourDepth 
        [System.IO.File]::WriteAllBytes($ScreenModePrefsFileUAE, $ScreenModePrefsToWrite)            
    }
    
    $EnvarcScreenModeChipsetPath = join-pathMulti $Script:Settings.InterimAmigaDrives "System" "Prefs" "Env-Archive" "ScreenModeChipset"
    $ScreenModeChipset = Check-WBScreenMode

    [System.IO.File]::WriteAllText($EnvarcScreenModeChipsetPath,$ScreenModeChipset,[System.Text.Encoding]::GetEncoding('iso-8859-1'))

    if ($ScreenModeChipset -eq "RTG"){
        $null = Copy-Item -Path $ScreenModePrefsFile "$ScreenModePrefsFile.Native"
    }

    if ($wifiprefs){
        $Script:Settings.CurrentSubTaskNumber ++
        $Script:Settings.CurrentSubTaskName = "Creating Wifi Prefs"
        Write-StartSubTaskMessage

        $WirelessPrefs = (Get-WirelessPrefs -SSID $Script:GUIActions.SSID -WifiPassword $Script:GUIActions.WifiPassword)
        $ExportFileDestination = Join-pathMulti $Script:Settings.InterimAmigaDrives "System" "Prefs" "Env-Archive" "Sys" "wireless.prefs"

        Export-TextFile -Amiga -DatatoExport $WirelessPrefs -AddLineFeeds -ExportFile $ExportFileDestination
    }

    $Script:Settings.CurrentSubTaskNumber ++
    $Script:Settings.CurrentSubTaskName = "Creating new folders and/or adding .info files where needed"
    Write-StartSubTaskMessage
    
    $FolderstoAdd = ((Get-InputFileCSV "FolderstoAdd").where({$_.PackageName.Trim() -in ($ValidPackages + $ValidOSPackages) }) | Select-Object DrivetoInstall,LocationtoInstall,CreateInfoFile)
    $FolderstoAdd += (Get-NewInstallPathFolders | Select-Object DrivetoInstall,LocationtoInstall,CreateInfoFile)
    $FolderstoAdd = $FolderstoAdd | Select-object DrivetoInstall, LocationtoInstall, CreateInfoFile -unique 

    Foreach ($Folder in $FolderstoAdd){
        $DestinationFolder = Join-PathMulti $Script:Settings.InterimAmigaDrives $Folder.DrivetoInstall $Folder.LocationtoInstall
        if (-not (Test-Path $DestinationFolder -PathType Container)){
            $null = New-Item $DestinationFolder -ItemType Directory -Force
        }
        if ($Folder.CreateInfoFile -eq $true){
            $DestinationPath = "$DestinationFolder.info"
            if (-not (Test-Path $DestinationPath)){
                $SourcePath = Join-PathMulti $Script:Settings.TempFolder "IconFiles" "NewFolder.info"  
                $null = Copy-Item $SourcePath $DestinationPath           
            }
        }

    } 
      
    Write-TaskCompleteMessage 
    $Script:Settings.CurrentTaskName = "Moving WBStartup files for first boot"
    Write-StartTaskMessage
    $WBStartupPath = join-pathMulti $Script:Settings.InterimAmigaDrives "System" "WBStartup"
    $FilestoMove = Get-ChildItem -Path $WBStartupPath
    $FilestoMoveDestination = join-path $WBStartupPath "Disabled"
    
    if (-not (test-path $FilestoMoveDestination -PathType Container)){
        $null = New-Item -path $FilestoMoveDestination -ItemType Directory 
    } 
    
    if (-not (test-path "$FilestoMoveDestination.info")){
        $SourcePath = Join-PathMulti $Script:Settings.TempFolder "IconFiles" "NewFolder.info"
        $null = Copy-Item $SourcePath "$FilestoMoveDestination.info"    

    }

    $FilestoMove |  Where-Object {$_.Name -ne 'Disabled' -and $_.Name -ne 'OnetimeRunWB.info' -and $_.Name -ne 'OnetimeRunWB'}  |  ForEach-Object {
        $null = move-item -Path $_.FullName -Destination $FilestoMoveDestination -Force 
    }
    
    Write-TaskCompleteMessage
      
} 