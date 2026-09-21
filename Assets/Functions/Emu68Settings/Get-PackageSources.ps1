function Get-PackageSources {
    param (        
        [Switch]$Emu68
    )
    
    if ($Script:GUICurrentStatus.AvailablePackagesNeedingGeneration -eq "TRUE"){
        Get-SelectablePackages
        $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = "FALSE"
    }
    elseif ($Script:GUICurrentStatus.AvailablePackagesNeedingGeneration -eq "KeepInstallPaths"){
        Get-SelectablePackages -KeepInstallStatus
        $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = "FALSE"
    }
      

    $PackageStatus = @{}
 
    $AllowedTypes = @()
    if (-not $Emu68){
        $AllowedTypes += "Mandatory Package"
        $AllowedTypes += "Selectable Package - DefaultInstall"
        $AllowedTypes += "Selectable Package"
       # $AllowedTypes += "Selectable Package - USB - DefaultInstall"
       # $AllowedTypes += "Selectable Package - Network - DefaultInstall"
    }
        

    if (-not $Emu68){
        if ($Script:GUIActions.SelectedIconSet){
            $IconsettoUse = $Script:GUIActions.SelectedIconSet
        }
        else {
            $IconsettoUse = ((Get-InputFileCSV -CSV 'IconSets') | Where-Object { $_.IconsDefaultInstall -eq $true}).Iconset
        }
    }
    
    $AdditionalPackagesList = @()
   
    If ($Emu68) {
        $AdditionalPackagesList = @((Get-ConfigurablePackages -Emu68Packages).where({$_.IndexOf("Core Files") -gt 0 }))
        $PackagesList = (Get-InputFileCSV -CSV 'Packages').Where({ $_.PackageName -in $AdditionalPackagesList })
    }
    else {
        $AdditionalPackagesList += Get-ConfigurablePackages -Emu68Packages
        $AdditionalPackagesList += Get-ConfigurablePackages -USBStackPackages
        $AdditionalPackagesList += Get-ConfigurablePackages -GenetPackages
        $AdditionalPackagesList += Get-ConfigurablePackages -PoseidonPackages
        $AdditionalPackagesList += Get-ConfigurablePackages -NetworkStackPackages
        $AdditionalPackagesList += Get-ConfigurablePackages -MUIPackages 
        $PackagesList = (Get-InputFileCSV -CSV 'Packages').Where({ (($_.PackageName -in $AdditionalPackagesList) -or ($_.PackageType -in $AllowedTypes)) })
    }
    
    $PackagesList.foreach({
        $IsSelected = ($_.PackageType -in @("Mandatory Package","Emu68","Genet","MUI","NetworkStack","Poseidon","USB Stack","UserFile"))
        $PackageStatus[$_.PackageName] = [PSCustomObject]@{    
            PackageType = $_.PackageType 
            PackageSelected = $IsSelected
        }                
    }) 

    if (-not $Emu68){
        $Script:GUIActions.AvailablePackages.DefaultView | ForEach-Object {
            if ($PackageStatus[$_.PackageName] -and $_.PackageNameUserSelected -eq $true) {
                $PackageStatus[$_.PackageName].PackageSelected = $true      
            }
        }
    }

    $ValidPackages = $PackagesList.PackageName
    $PackageSources = (Get-InputFileCSV -CSV 'PackageSources').where({ ($_.PackageName -in $ValidPackages) }) | select-object PackageName, SourceType, SourceLocation, URL, AlwaysDownload, GithubReleaseType, GithubName, GithubNameExclude, GithubSortTagPrefix,	GithubSortSemanticVersion, GithubRelease, UpdatePackageSearchTerm, UpdatePackageSearchResultLimit, UpdatePackageSearchExclusionTerm, UpdatePackageSearchMinimumDate, BackupURL, PerformHashCheck, Hash, UseLHASA, ArchiveinArchiveName -unique
    $TotalSources = [System.Collections.Generic.List[PSCustomObject]]::new()
    
    # $TotalSources.where({ $_.PackageName -eq "Roadshow - Full" -or $_.PackageName -eq "Roadshow - Common" })    
    # $PackageSources.where({ $_.PackageName -eq "Roadshow - Full" -or $_.PackageName -eq "Roadshow - Common" }) 
    #$TotalSources >test.txt

    foreach ($Source in $PackageSources){
        $PackageSelected = $PackageStatus[$Source.PackageName]
        $Status = $PackageSelected.PackageSelected
        $PackageType = $PackageSelected.PackageType
        if ($PackageType -eq "UserFile"){
            if ($Source.PackageName -eq "Roadshow - Full"){
                $SourceLocation = $Script:GUICurrentStatus.RoadshowUserFiles.ArchiveName
                #$Folder = [System.IO.Path]::GetFileNameWithoutExtension($Script:GUICurrentStatus.RoadshowUserFiles.ArchiveName)
                $Folder = [System.IO.Path]::GetFileName($Script:GUICurrentStatus.RoadshowUserFiles.ArchiveName)
                #$SourcePath = Join-Path $Folder $PackageSelected.SourcePath
                $OutputLocation = [System.IO.Path]::GetFullPath((join-path $Script:Settings.WebPackagesDownloadLocation $Folder))
            }
            elseif ($Source.PackageName -eq "Miami - Full"){
                $SourceLocation = $null
                $SourcePath  = Join-Path $Script:GUICurrentStatus.MiamiUserFiles $PackageSelected.SourcePath
                $OutputLocation =  $SourcePath 
            }
            elseif ($Source.PackageName -eq "Picasso96 - Full"){
                # Not built                
            }
        }
        elseif ($Source.SourceType  -eq "Local - Archive"){
            $SourceLocation = Join-PathMulti $Script:Settings.LocalAmigaPackagesLocation $Source.SourceLocation -UseFullPath
            $Folder = $Source.SourceLocation 
            $OutputLocation = [System.IO.Path]::GetFullPath((join-path $Script:Settings.WebPackagesDownloadLocation $Folder))
        }
        else {
            $SourceLocation = $Source.SourceLocation
            If ($Source.SourceType -match "Web"){
              #  $SourcePath = $PackageSelected.SourcePath
              $OutputLocation = [System.IO.Path]::GetFullPath((join-path $Script:Settings.WebPackagesDownloadLocation $Source.SourceLocation))
            }  
            elseif ($Source.SourceType -in @("Local - Files - Cmdline.txt", "Local - Files - Config.txt")){ 
              #  $SourcePath = $PackageSelected.SourcePath           
                $OutputLocation = Join-PathMulti $Script:Settings.Emu68ImagerSupportingFiles $Source.SourceLocation -UseFullPath
            }              
            elseif ($Source.SourceType -in @("Local - Files")){ 
              #  $SourcePath = $PackageSelected.SourcePath           
                $OutputLocation = Join-PathMulti $Script:Settings.LocationofAmigaFiles $Source.SourceLocation -UseFullPath
            } 
            else {
              #  $SourcePath = $PackageSelected.SourcePath
                $OutputLocation = "ERROR"
            }            
        }
        If ($Status){
            $TotalSources.Add([PSCustomObject]@{
              #  PackageType = $PackageType
                PackageName = $Source.PackageName
               # PackageSelected  = [bool]::Parse($PackageSelected.PackageSelected)         
                SourceType = $Source.SourceType
                SourceLocation = $SourceLocation
                OutputLocation = $OutputLocation
                URL = $Source.URL
                AlwaysDownload = $Source.AlwaysDownload
                GithubReleaseType = $Source.GithubReleaseType
                GithubName = $Source.GithubName
                GithubNameExclude = $Source.GithubNameExclude
                GithubSortTagPrefix = $Source.GithubSortTagPrefix
                GithubSortSemanticVersion = $Source.GithubSortSemanticVersion
                GithubRelease = $Source.GithubRelease
                UpdatePackageSearchTerm = $Source.UpdatePackageSearchTerm
                UpdatePackageSearchResultLimit = $Source.UpdatePackageSearchResultLimit
                UpdatePackageSearchExclusionTerm = $Source.UpdatePackageSearchExclusionTerm
                UpdatePackageSearchMinimumDate = $Source.UpdatePackageSearchMinimumDate
                BackupURL = $Source.BackupURL
                PerformHashCheck = [bool]::Parse($Source.PerformHashCheck)
                Hash = $Source.Hash
                UseLHASA = $Source.UseLHASA
                ArchiveinArchiveName = $Source.ArchiveinArchiveName
                DownloadFileFlag = $null
                RevisedDownloadURL = $null
            })
        }
    }
 
    $ListofFieldstoGroup = $TotalSources[0].psobject.Properties.Name | Where-Object { $_ -notin 'PackageName', 'ArchiveinArchiveName' }
    
    $TotalSourcesGrouped = $TotalSources | Group-Object -Property $ListofFieldstoGroup | ForEach-Object {
        $mergedObject = $_.Group[0].psobject.Copy()
        $mergedObject.PackageName = $_.Group.PackageName -join ', '
        $mergedObject.ArchiveinArchiveName = ($_.Group.ArchiveinArchiveName | Where-Object { $_ }) -join ', '
        $mergedObject
    }

    return $TotalSourcesGrouped 
    
}
