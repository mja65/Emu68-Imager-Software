function Get-InputCSVs {
    param (
      [switch]$OSestoInstall,
      [switch]$IconSets,
      [Switch]$Diskdefaults,
      [switch]$ROMHashes,
      [switch]$InstallMediaHashes,
      [switch]$ScreenModes,
      [switch]$ScreenModesWB,
      [switch]$PackagestoInstall,
      [switch]$PackagestoInstallEmu68Only,
      [switch]$FileSystems,
      [switch]$IconPositions,
      [switch]$DocumentationURLs

    )
    

    if ($OSestoInstall){
        $Pathtouse = $Script:Settings.OSVersionstoInstallCSV.Path 
    }
    elseif ($IconSets){
        $Pathtouse = $Script:Settings.IconSetsCSV.Path 
    }
    elseif ($Diskdefaults){
        $Pathtouse = $Script:Settings.DiskDefaultsCSV.Path
    }
    elseif ($FileSystems){
        $Pathtouse = $Script:Settings.FileSystemsCSV.Path
    }
    elseif ($ScreenModes){
        $Pathtouse = $Script:Settings.ScreenModesCSV.Path
    }
    elseif ($ScreenModesWB){
        $Pathtouse = $Script:Settings.ScreenModesWBCSV.Path
    }    
    elseif ($RomHashes){
        $Pathtouse = $Script:Settings.ROMHashesCSV.Path
    }
    elseif ($InstallMediaHashes){
        $Pathtouse = $Script:Settings.InstallMediaHashesCSV.Path
    }
    elseif (($PackagestoInstall) -or ($PackagestoInstallEmu68Only)){
        $Pathtouse = $Script:Settings.ListofPackagestoInstallCSV.Path
    }
    elseif ($IconPositions){
        $Pathtouse = $Script:Settings.IconPositionsCSV.Path
    }
    elseif ($DocumentationURLs){
        $Pathtouse = $Script:Settings.DocumentationURLsCSV.Path
    }

    $CSV = @()
    
    import-csv -path $Pathtouse -Delimiter ";" | ForEach-Object {
        if ($_.MinimumInstallerVersion -ne "" -and $_.InstallerVersionLessThan -ne ""){
            if (($Script:Settings.Version -ge [system.version]$_.MinimumInstallerVersion) -and ($Script:Settings.Version -lt [system.version]$_.InstallerVersionLessThan)){
                $CSV += $_
            }
        }
    }
 
    if ($OSestoInstall){
        $CSVtoReturn = $CSV | Select-Object 'Kickstart_Version','Kickstart_VersionFriendlyName','InstallMedia','NewFolderIconSource','NewFolderIconSourceType','NewFolderIconSourcePath','WorkbenchIconSource','WorkbenchIconSourceType','WorkbenchIconSourcePath','WorkbenchModifyInfoFileType','WorkIconSource','WorkIconSourceType','WorkIconSourcePath','WorkModifyInfoFileType','Emu68BootIconSource','Emu68BootIconSourceType','Emu68BootIconSourcePath','Emu68BootModifyInfoFileType'

    }
    elseif ($IconSets){

        $CSVtoReturn = [System.Collections.Generic.List[PSCustomObject]]::New()

        $CSV | ForEach-Object {
            $CountofVariables = ([regex]::Matches($_.KickstartVersion, "," )).count
            if ($CountofVariables -gt 0){
                $Counter = 0
                do {
                    $CSVtoReturn += [PSCustomObject]@{                              
                        MinimumInstallerVersion = [system.version]$_.MinimumInstallerVersion
                        InstallerVersionLessThan = [system.version]$_.InstallerVersionLessThan
                        KickstartVersion = [system.version](($_.KickstartVersion -split ',')[$Counter]) 

                        IconsetName = $_.IconsetName
                        IconSetDescription  = $_.IconSetDescription
                        IconsDefaultInstall = $_.IconsDefaultInstall
                        NewFolderIconSource = $_.NewFolderIconSource
                        NewFolderIconSourceLocation = $_.NewFolderIconSourceLocation
                        NewFolderIconInstallMedia = $_.NewFolderIconInstallMedia
                        NewFolderIconFilestoInstall = $_.NewFolderIconFilestoInstall
                        NewFolderIconModifyInfoFileType = $_.NewFolderIconModifyInfoFileType
                        SystemDiskIconSource = $_.SystemDiskIconSource
                        SystemDiskIconSourceLocation = $_.SystemDiskIconSourceLocation
                        SystemDiskIconInstallMedia = $_.SystemDiskIconInstallMedia
                        SystemDiskIconFilestoInstall = $_.SystemDiskIconFilestoInstall
                        SystemDiskIconModifyInfoFileType = $_.SystemDiskIconModifyInfoFileType
                        WorkDiskIconSource = $_.WorkDiskIconSource
                        WorkDiskIconSourceLocation = $_.WorkDiskIconSourceLocation
                        WorkDiskIconInstallMedia = $_.WorkDiskIconInstallMedia
                        WorkDiskIconFilestoInstall = $_.WorkDiskIconFilestoInstall
                        WorkDiskIconModifyInfoFileType = $_.WorkDiskIconModifyInfoFileType
                        Emu68BootDiskIconSource = $_.Emu68BootDiskIconSource
                        Emu68BootDiskIconSourceLocation = $_.Emu68BootDiskIconSourceLocation
                        Emu68BootDiskIconInstallMedia = $_.Emu68BootDiskIconInstallMedia
                        Emu68BootDiskIconFilestoInstall = $_.Emu68BootDiskIconFilestoInstall
                        Emu68BootModifyInfoFileType = $_.Emu68BootModifyInfoFileType                                     
                    }
                    $counter ++
                 } until (
                        $Counter -eq ($CountofVariables+1)
                    )
            }
            else {        
                $CSVtoReturn += [PSCustomObject]@{
                    MinimumInstallerVersion = [system.version]$_.MinimumInstallerVersion
                    InstallerVersionLessThan = [system.version]$_.InstallerVersionLessThan
                    KickstartVersion = [system.version]$_.KickstartVersion   


                    IconsetName = $_.IconsetName
                    IconSetDescription  = $_.IconSetDescription
                    IconsDefaultInstall = $_.IconsDefaultInstall
                    NewFolderIconSource = $_.NewFolderIconSource
                    NewFolderIconSourceLocation = $_.NewFolderIconSourceLocation
                    NewFolderIconInstallMedia = $_.NewFolderIconInstallMedia
                    NewFolderIconFilestoInstall = $_.NewFolderIconFilestoInstall
                    NewFolderIconModifyInfoFileType = $_.NewFolderIconModifyInfoFileType
                    SystemDiskIconSource = $_.SystemDiskIconSource
                    SystemDiskIconSourceLocation = $_.SystemDiskIconSourceLocation
                    SystemDiskIconInstallMedia = $_.SystemDiskIconInstallMedia
                    SystemDiskIconFilestoInstall = $_.SystemDiskIconFilestoInstall
                    SystemDiskIconModifyInfoFileType = $_.SystemDiskIconModifyInfoFileType
                    WorkDiskIconSource = $_.WorkDiskIconSource
                    WorkDiskIconSourceLocation = $_.WorkDiskIconSourceLocation
                    WorkDiskIconInstallMedia = $_.WorkDiskIconInstallMedia
                    WorkDiskIconFilestoInstall = $_.WorkDiskIconFilestoInstall
                    WorkDiskIconModifyInfoFileType = $_.WorkDiskIconModifyInfoFileType
                    Emu68BootDiskIconSource = $_.Emu68BootDiskIconSource
                    Emu68BootDiskIconSourceLocation = $_.Emu68BootDiskIconSourceLocation
                    Emu68BootDiskIconInstallMedia = $_.Emu68BootDiskIconInstallMedia
                    Emu68BootDiskIconFilestoInstall = $_.Emu68BootDiskIconFilestoInstall
                    Emu68BootModifyInfoFileType = $_.Emu68BootModifyInfoFileType                                 
                }
            }
        }

       
        $CSVtoReturn = $CSVtoReturn | Where-Object {$_.KickstartVersion -eq $Script:GUIActions.KickstartVersiontoUse}
        
    }
    elseif ($FileSystems) {
        $CSVtoReturn = $CSV
    }
    elseif ($Diskdefaults){
        $CSVtoReturn = $CSV
    }
    elseif ($ScreenModes){
        $CSVtoReturn = $CSV | Where-Object 'Include' -eq 'TRUE'
    }
    elseif ($ScreenModesWB){
        $CSVtoReturn = $CSV | Where-Object 'Include' -eq 'TRUE'
    }     
    elseif ($RomHashes){
        $CSVtoReturn = $CSV | Select-Object 'IncludeorExclude','ExcludeMessage','Kickstart_Version','Sequence','Hash','FriendlyName','FAT32Name' | Where-Object {$_.Kickstart_Version -eq $Script:GUIActions.KickstartVersiontoUse}
    }
    elseif ($InstallMediaHashes){
        $CSVtoReturn = $CSV | Select-Object 'Sequence', 'WorkbenchVersion', 'Hash', 'TypeofCheck','FilesChecked','FileCheckDetails','InstallMedia', 'ADF_Name', 'FriendlyName', 'ADFSource', 'ADFDescription' 
    }

    elseif (($PackagestoInstall) -or ($PackagestoInstallEmu68Only)){
        
        $CSVtoReturn = [System.Collections.Generic.List[PSCustomObject]]::New()

        $CSV | ForEach-Object {
            $CountofVariables = ([regex]::Matches($_.KickstartVersion, "," )).count
            if ($CountofVariables -gt 0){
                $Counter = 0
                do {
                    $CSVtoReturn += [PSCustomObject]@{                              
                        MinimumInstallerVersion = [system.version]$_.MinimumInstallerVersion
                        InstallerVersionLessThan = [system.version]$_.InstallerVersionLessThan
                        KickstartVersion = [system.version](($_.KickstartVersion -split ',')[$Counter]) 
                        IconSetName = $_.IconSetName
                        PackageName = $_.PackageName
                        PackageMandatory =	$_.PackageMandatory
                        PackageNameDefaultInstall = $_.PackageNameDefaultInstall 
                        PackageNameFriendlyName = $_.PackageNameFriendlyName
                        PackageNameGroup = $_.PackageNameGroup 
                        PackageNameDescription = $_.PackageNameDescription
                        UpdatePackageSearchTerm = $_.UpdatePackageSearchTerm
                        UpdatePackageSearchResultLimit = $_.UpdatePackageSearchResultLimit
                        UpdatePackageSearchExclusionTerm = $_.UpdatePackageSearchExclusionTerm
                        UpdatePackageSearchMinimumDate = $_.UpdatePackageSearchMinimumDate
                        InstallSequence = $_.InstallSequence
                        Source = $_.Source
                        GithubReleaseType = $_.GithubReleaseType
                        GithubName = $_.GithubName
                        GithubRelease = $_.GithubRelease
                        InstallType = $_.InstallType
                        SourceLocation = $_.SourceLocation
                        BackupSourceLocation = $_.BackupSourceLocation
                        ArchiveinArchiveName = $_.ArchiveinArchiveName
                        ArchiveinArchivePassword = $_.ArchiveinArchivePassword
                        FileDownloadName = $_.FileDownloadName
                        PerformHashCheck = $_.PerformHashCheck
                        Hash = $_.Hash
                        FilestoInstall = $_.FilestoInstall
                        UseUAEFSDB = $_.UseUAEFSDB
                        DrivetoInstall = $_.DrivetoInstall
                        LocationtoInstall = $_.LocationtoInstall
                        CopytoAmigaDriveDirect = $_.CopytoAmigaDriveDirect
                        CopyRecursive = $_.CopyRecursive
                        UncompressZFiles = $_.UncompressZFiles
                        CreateFolderInfoFile = $_.CreateFolderInfoFile
                        NewFileName = $_.NewFileName
                        ScriptBeingModified = $_.ScriptBeingModified
                        ModifyScript  = $_.ModifyScript 
                        ModifyScriptAction = $_.ModifyScriptAction
                        ScriptNameofChange = $_.ScriptNameofChange
                        ScriptEditStartPoint = $_.ScriptEditStartPoint
                        ScriptEditEndPoint = $_.ScriptEditEndPoint
                        ScriptPathtoChanges = $_.ScriptPathtoChanges
                        ScriptArexxFlag = $_.ScriptArexxFlag
                        ModifyInfoFileType = $_.ModifyInfoFileType
                        ModifyInfoFileTooltype  = $_.ModifyInfoFileTooltype 
                        PathtoRevisedToolTypeInfo = $_.PathtoRevisedToolTypeInfo                                                            
                    }
                    $counter ++
                 } until (
                        $Counter -eq ($CountofVariables+1)
                    )
            }
            else {
                $CSVtoReturn += [PSCustomObject]@{
                    MinimumInstallerVersion = [system.version]$_.MinimumInstallerVersion
                    InstallerVersionLessThan = [system.version]$_.InstallerVersionLessThan
                    KickstartVersion = [system.version]$_.KickstartVersion
                    IconSetName = $_.IconSetName
                    PackageName = $_.PackageName
                    PackageMandatory =	$_.PackageMandatory
                    PackageNameDefaultInstall = $_.PackageNameDefaultInstall 
                    PackageNameFriendlyName = $_.PackageNameFriendlyName
                    PackageNameGroup = $_.PackageNameGroup 
                    PackageNameDescription = $_.PackageNameDescription
                    UpdatePackageSearchTerm = $_.UpdatePackageSearchTerm
                    UpdatePackageSearchResultLimit = $_.UpdatePackageSearchResultLimit
                    UpdatePackageSearchExclusionTerm = $_.UpdatePackageSearchExclusionTerm
                    UpdatePackageSearchMinimumDate = $_.UpdatePackageSearchMinimumDate
                    InstallSequence = $_.InstallSequence
                    Source = $_.Source
                    GithubReleaseType = $_.GithubReleaseType
                    GithubName = $_.GithubName
                    GithubRelease = $_.GithubRelease                    
                    InstallType = $_.InstallType
                    SourceLocation = $_.SourceLocation
                    BackupSourceLocation = $_.BackupSourceLocation
                    ArchiveinArchiveName = $_.ArchiveinArchiveName
                    ArchiveinArchivePassword = $_.ArchiveinArchivePassword
                    FileDownloadName = $_.FileDownloadName
                    PerformHashCheck = $_.PerformHashCheck
                    Hash = $_.Hash
                    FilestoInstall = $_.FilestoInstall
                    UseUAEFSDB = $_.UseUAEFSDB
                    DrivetoInstall = $_.DrivetoInstall
                    LocationtoInstall = $_.LocationtoInstall
                    CopytoAmigaDriveDirect = $_.CopytoAmigaDriveDirect
                    CopyRecursive = $_.CopyRecursive
                    UncompressZFiles = $_.UncompressZFiles
                    CreateFolderInfoFile = $_.CreateFolderInfoFile
                    NewFileName = $_.NewFileName
                    ScriptBeingModified = $_.ScriptBeingModified
                    ModifyScript  = $_.ModifyScript 
                    ModifyScriptAction = $_.ModifyScriptAction
                    ScriptNameofChange = $_.ScriptNameofChange
                    ScriptEditStartPoint = $_.ScriptEditStartPoint
                    ScriptEditEndPoint = $_.ScriptEditEndPoint
                    ScriptPathtoChanges = $_.ScriptPathtoChanges
                    ScriptArexxFlag = $_.ScriptArexxFlag
                    ModifyInfoFileType = $_.ModifyInfoFileType
                    ModifyInfoFileTooltype  = $_.ModifyInfoFileTooltype 
                    PathtoRevisedToolTypeInfo = $_.PathtoRevisedToolTypeInfo                                                                         
                }
            }
        }

        if ($PackagestoInstall){
            $CSVtoReturn = $CSVtoReturn | Where-Object {$_.KickstartVersion -eq $Script:GUIActions.KickstartVersiontoUse}
        } 
        elseif ($PackagestoInstallEmu68Only){
            $CSVtoReturn = $CSVtoReturn | Where-Object {$_.DrivetoInstall -eq 'Emu68Boot'}
        }
    }
    
    elseif ($IconPositions){
        
        $CSVtoReturn = [System.Collections.Generic.List[PSCustomObject]]::New()
        
        $CSV | ForEach-Object {
            $CountofVariables = ([regex]::Matches($_.KickstartVersion, "," )).count
            if ($CountofVariables -gt 0){
                $Counter = 0
                do {
                    $CSVtoReturn += [PSCustomObject]@{                              
                        MinimumInstallerVersion = [system.version]$_.MinimumInstallerVersion
                        InstallerVersionLessThan = [system.version]$_.InstallerVersionLessThan
                        Include = $_.Include
                        KickstartVersion = [system.version](($_.KickstartVersion -split ',')[$Counter]) 
                        Drive = $_.Drive	
                        File = $_.File		
                        Type = $_.Type		
                        IconX = $_.IconX
                        IconY = $_.IconY	
                        DrawerX	= $_.DrawerX
                        DrawerY	= $_.DrawerY
                        DrawerWidth	= $_.DrawerWidth
                        DrawerHeight= $_.DrawerHeight	                        
                    }
                    $counter ++
                 } until (
                        $Counter -eq ($CountofVariables+1)
                    )
            }
            else {        
                $CSVtoReturn += [PSCustomObject]@{
                    MinimumInstallerVersion = [system.version]$_.MinimumInstallerVersion
                    InstallerVersionLessThan = [system.version]$_.InstallerVersionLessThan
                    Include = $_.Include  
                    KickstartVersion = [system.version]$_.KickstartVersion  
                    Drive = $_.Drive	
                    File = $_.File		
                    Type = $_.Type		
                    IconX = $_.IconX
                    IconY = $_.IconY	
                    DrawerX	= $_.DrawerX
                    DrawerY	= $_.DrawerY
                    DrawerWidth	= $_.DrawerWidth
                    DrawerHeight= $_.DrawerHeight	                     
                }
            }
        }

        $CSVtoReturn = $CSVtoReturn | Where-Object {($_.KickstartVersion -eq $Script:GUIActions.KickstartVersiontoUse) -and ($_.include -eq $true)} 
    }
    
    elseif ($DocumentationURLs) {
        $CSVtoReturn = $CSV | Select-Object 'URL'
    }

    return $CSVtoReturn
}

