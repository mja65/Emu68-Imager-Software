function Get-PackageSources {
    param (        
        [Switch]$Emu68
    )
    
    if ($Script:GUICurrentStatus.AvailablePackagesNeedingGeneration -eq $true){
        Get-SelectablePackages
        $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = $false
    }

    $PackageStatus = @{}
    $PackagesList = @()

    $AllowedTypes = @()
    $AllowedTypes += "Emu68"
    if (-not $Emu68){ $AllowedTypes += "Package" }

    if (-not $Emu68){
        if ($Script:GUIActions.SelectedIconSet){
            $IconsettoUse = $Script:GUIActions.SelectedIconSet
        }
        else {
            $IconsettoUse = ((Get-InputFileCSV -CSV 'IconSets') | Where-Object { $_.IconsDefaultInstall -eq $true}).Iconset
        }
    }
   
    $PackagesList = (Get-InputFileCSV -CSV 'Packages').where({ $_.Type -in $AllowedTypes })
    
    $PackagesList.foreach({
        $IsSelected = ($_.PackageType -eq "Mandatory") -or 
            ($_.PackageType -eq "NetworkStack" -and $_.NetworkStack -eq $Script:GUIActions.NetworkStack) -or 
            ($_.PackageType -eq "USBStack" -and $_.USBStack -eq $Script:GUIActions.USBStack)
        
        $PackageStatus[$_.PackageName] = [PSCustomObject]@{       
            PackageType = $_.PackageType 
            USBStack = $_.USBStack
            NetworkStack = $_.NetworkStack
            PackageSelected = $IsSelected
        }                
    }) 

    if (-not $Emu68){
        $Script:GUIActions.AvailablePackages | ForEach-Object {
            if ($PackageStatus[$_.PackageName] -and $_.PackageNameUserSelected -eq $true) {
                $PackageStatus[$_.PackageName].PackageSelected = $true      
            }
        }
    }

    $ValidPackages = $PackagesList.PackageName
    $PackageSources = (Get-InputFileCSV -CSV 'PackageSources').where({ ($_.PackageName -in $ValidPackages) }) | select-object PackageName, SourceType, SourceLocation, URL, AlwaysDownload, GithubReleaseType, GithubName, GithubRelease, UpdatePackageSearchTerm, UpdatePackageSearchResultLimit, UpdatePackageSearchExclusionTerm, UpdatePackageSearchMinimumDate, BackupURL, PerformHashCheck, Hash, UseLHASA, ArchiveinArchiveName -unique

    $TotalSources = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($Source in $PackageSources){
        $PackageSelected = $PackageStatus[$Source.PackageName]
        $Status = $PackageSelected.PackageSelected
        If ($Source.SourceType -match "Web"){
            $OutputLocation = [System.IO.Path]::GetFullPath((join-path $Script:Settings.WebPackagesDownloadLocation $Source.SourceLocation))
        }
        elseif ($Source.SourceType -eq "Local - Archive"){
            $OutputLocation = Join-PathMulti $Script:Settings.LocationofAmigaFiles "LocalAmigaPackages" $Source.SourceLocation -UseFullPath

        }  
        elseif ($Source.SourceType -in @("Local - Files", "Local - Files - Cmdline.txt", "Local - Files - Config.txt")){            
            $OutputLocation = Join-PathMulti $Script:Settings.LocationofAmigaFiles $Source.SourceLocation -UseFullPath
        } 
        else {
            $OutputLocation = "ERROR"
        }
        If ($Status){
            $TotalSources.Add([PSCustomObject]@{
                PackageName = $Source.PackageName
               # PackageSelected  = [bool]::Parse($PackageSelected.PackageSelected)         
                SourceType = $Source.SourceType
                SourceLocation = $Source.SourceLocation
                OutputLocation = $OutputLocation
                URL = $Source.URL
                AlwaysDownload = $Source.AlwaysDownload
                GithubReleaseType = $Source.GithubReleaseType
                GithubName = $Source.GithubName
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