function Confirm-RequiredSources {
    param (
    )
    
    if ($Script:GUICurrentStatus.AvailablePackagesNeedingGeneration -eq $true){
        Get-SelectablePackages
        $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = $false
    }

    

    $OSandPackagesSources = Get-InputCSVs -PackagestoInstall | Where-Object { ($_.KickstartVersion -eq $Script:GUIActions.KickstartVersiontoUse) -and  ($_.IconsetName -eq "" -or $_.IconsetName -eq $Script:GUIActions.SelectedIconSet) } | Select-Object 'SourceLocation','Source','PackageNameFriendlyName' -Unique # Unique Source files Required
    
    $CombinedSources = [System.Collections.Generic.List[PSCustomObject]]::New()
    
    Get-InputCSVs -IconSets | ForEach-Object {
        $CombinedSources += [PSCustomObject]@{
            SourceLocation = $_.NewFolderIconSource
            Source = $_.NewFolderIconInstallMedia
            PackageNameFriendlyName = ""
        }
        $CombinedSources += [PSCustomObject]@{
            SourceLocation = $_.SystemDiskIconSource
            Source = $_.SystemDiskIconInstallMedia
            PackageNameFriendlyName = ""
        }
        $CombinedSources += [PSCustomObject]@{
            SourceLocation = $_.WorkDiskIconSource
            Source = $_.WorkDiskIconInstallMedia
            PackageNameFriendlyName = ""
        }
        $CombinedSources += [PSCustomObject]@{
            SourceLocation = $_.Emu68BootDiskIconSource
            Source = $_.Emu68BootDiskIconInstallMedia
            PackageNameFriendlyName = ""
        }
    }

    $OSandPackagesSources += $CombinedSources 

    $OSandPackagesSources  | Add-Member -NotePropertyName 'RequiredFlagUserSelectable' -NotePropertyValue $null
    $HashTableforSelectedPackages = @{} # Clear Hash
    $Script:GUIActions.AvailablePackages | ForEach-Object {
        $HashTableforSelectedPackages[$_.PackageNameFriendlyName] = @($_.PackageNameUserSelected)
    }

    $OSandPackagesSources | ForEach-Object {
        if ($HashTableforSelectedPackages.ContainsKey($_.PackageNameFriendlyName)){
            $_.RequiredFlagUserSelectable = $HashTableforSelectedPackages.($_.PackageNameFriendlyName)[0]
        }
        else {
            $_.RequiredFlagUserSelectable = 'Mandatory'
        }        
    }

    return ($OSandPackagesSources | Select-Object 'Source','SourceLocation','RequiredFlagUserSelectable' -Unique)

}