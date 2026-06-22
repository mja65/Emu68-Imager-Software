function Get-OSSources {
    param (        
    )
    
    $InstallMediaDescriptions = @{}
    $PackageStatus = @{}

     if ($Script:GUICurrentStatus.AvailablePackagesNeedingGeneration -eq $true){
        Get-SelectablePackages
        $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = $false
    }
      
    Get-InputFileCSV -CSV 'InstallMediaHashes' | Select-Object ADF_Name, FriendlyName -Unique | ForEach-Object {
        $InstallMediaDescriptions[$_.ADF_Name] = $_.FriendlyName
    }
    
    
    $PackagesList = (Get-InputFileCSV -CSV 'Packages').where({ $_.Type -eq "OS" })
    
    $PackagesList.foreach({
        $Status = $false
        If ($_.PackageType -eq "Mandatory") {
            $Status = $true
        }
        $PackageStatus[$_.PackageName] = [PSCustomObject]@{       
            PackageType = $_.PackageType 
            PackageSelected = $Status
        }                
    }) 

   $Script:GUIActions.AvailablePackages | ForEach-Object {
        if ($PackageStatus[$_.PackageName] -and $_.PackageNameUserSelected -eq $true) {
            $PackageStatus[$_.PackageName].PackageSelected = $_.PackageNameUserSelected       
        }
    }

    if ($Script:GUIActions.SelectedIconSet){
        $IconsettoUse = $Script:GUIActions.SelectedIconSet
    }
    else {
        $IconsettoUse = ((Get-InputFileCSV -CSV 'IconSets') | Where-Object {  $_.IconsDefaultInstall -eq $true}).Iconset
    }
    
    $MatchedIconSet = @(Get-InputFileCSV -CSV 'IconSets').Where({ $_.Iconset -eq $IconsettoUse })
      
    $IconSources = @(
        $MatchedIconSet.ForEach({        
            [PSCustomObject]@{ PackageName = 'OS Install'; SourceLocation = $_.NewFolderIconSource;       SourceType = $_.NewFolderIconInstallMedia; PackageSelected = $true }
            [PSCustomObject]@{ PackageName = 'OS Install'; SourceLocation = $_.SystemDiskIconSource;      SourceType = $_.SystemDiskIconInstallMedia; PackageSelected = $true}
            [PSCustomObject]@{ PackageName = 'OS Install'; SourceLocation = $_.WorkDiskIconSource;        SourceType = $_.WorkDiskIconInstallMedia; PackageSelected = $true }
            [PSCustomObject]@{ PackageName = 'OS Install'; SourceLocation = $_.Emu68BootDiskIconSource;   SourceType = $_.Emu68BootDiskIconInstallMedia; PackageSelected = $true }            
        }) | Select-Object -Property 'PackageName', 'SourceLocation', 'SourceType', 'CDParent', 'PackageSelected','ArchiveinArchiveName','ArchiveinArchivePassword' -Unique
    )    
        
    $OSSources = (Get-InputFileCSV -CSV 'OSSources') | Select-Object 'PackageName','SourceLocation','SourceType','CDParent','PackageSelected','ArchiveinArchiveName','ArchiveinArchivePassword' -Unique

    $TotalSources = [System.Collections.Generic.List[PSCustomObject]]::new()
    
    Foreach ($Source in ($IconSources + $OSSources)) {
        $InstallMediaFriendlyName = $InstallMediaDescriptions[$Source.SourceLocation]
        $PackageSelected = $PackageStatus[$Source.PackageName].PackageSelected   
        If (-not $PackageSelected -eq $true) {continue}
        $TotalSources.Add([PSCustomObject]@{
            PackageName    = $Source.PackageName
            SourceType     = $Source.SourceType
            CDParent = $(If ($Source.CDParent) {($Source.CDParent.toupper())} else {""})
            SourceLocation = $Source.SourceLocation
            ArchiveinArchiveName = $Source.ArchiveinArchiveName
            ArchiveinArchivePassword = $Source.ArchiveinArchivePassword
            InstallMediaFriendlyName  = $InstallMediaFriendlyName
           # PackageSelected = [bool]::Parse($PackageSelected)
        })   
    }

    $ListofFieldstoGroup = $TotalSources[0].psobject.Properties.Name | Where-Object { $_ -notin 'PackageName', 'ArchiveinArchiveName', 'ArchiveinArchivePassword', 'CDParent'}
        
    $TotalSourcesGrouped = $TotalSources | Group-Object -Property $ListofFieldstoGroup | ForEach-Object {
        $mergedObject = $_.Group[0].psobject.Copy()
        $mergedObject.PackageName = ($_.Group.PackageName | Select-Object -Unique) -join ', '
        $mergedObject.ArchiveinArchiveName = ($_.Group.ArchiveinArchiveName | Where-Object { $_ }) -join ', '
        $mergedObject.ArchiveinArchivePassword = ($_.Group.ArchiveinArchivePassword | Where-Object { $_ }) -join ', '
        $mergedObject.CDParent = ($_.Group.CDParent | Where-Object { $_ } | Select-Object -Unique) -join ', '
        $mergedObject
    }  

    return $TotalSourcesGrouped
   
}