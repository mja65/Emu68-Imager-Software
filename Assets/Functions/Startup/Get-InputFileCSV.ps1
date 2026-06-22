function Get-InputFileCSV {
    param($CSV)

    #$CSV = "Packages"

    $Target = $Script:InputCSVs.$CSV
    $HeaderArr = $Target.Headers
    $RowCount = $Target.Rows.Count
    
    $Results = [System.Collections.Generic.List[PSCustomObject]]::new($RowCount)
    $EmuVersion = $Script:GUIActions.Emu68VersiontoUse
    $KickstartVersion = $Script:GUIActions.KickstartVersiontoUse
    $IconSet = $Script:GUIActions.SelectedIconSet
    $VersionofScript = $Script:Settings.Version

    $IndexMinimumInstallerVersion = $HeaderArr.IndexOf("MinimumInstallerVersion")
    $IndexInstallerVersionLessThan = $HeaderArr.IndexOf("InstallerVersionLessThan")
    $IndexMinimumEmu68Version = $HeaderArr.IndexOf("MinimumEmu68Version")
    $IndexEmu68VersionLessThan = $HeaderArr.IndexOf("Emu68VersionLessThan")
    $IndexInclude = $HeaderArr.IndexOf("Include")
    $IndexKickstartVersion = $HeaderArr.IndexOf("KickstartVersion")
    $IndexIconSet = $HeaderArr.IndexOf("IconSet")

    if ($CSV -eq 'IconSets'){
        $IndexIconsDefaultInstall = $HeaderArr.IndexOf("IconsDefaultInstall")
    }

    $IndexesToSkip = @(
        $IndexMinimumEmu68Version
        $IndexMinimumInstallerVersion
        $IndexInstallerVersionLessThan
        $IndexEmu68VersionLessThan
        $IndexInclude
        if ($CSV -ne "IconSets") { $IndexIconSet }        
        if ($CSV -ne "OSVersionstoInstall") { $IndexKickstartVersion }
    ) | Where-Object { $_ -ne -1 } # Strip out columns that don't exist in this CSV

    $IndexesToKeep = [System.Collections.Generic.List[int]]::new($HeaderArr.Count)
    for ($i = 0; $i -lt $HeaderArr.Count; $i++) {
        if ($i -notin $IndexesToSkip) {
            $IndexesToKeep.Add($i)
        }
    }

    foreach ($RowData in $Target.Rows) {
        if ($IndexInclude -ne -1) {
            if ($RowData[$IndexInclude] -ne "TRUE"){ continue }
        }
        if ($IndexMinimumInstallerVersion -ne -1) {
            if ($VersionofScript -lt [System.Version]$RowData[$IndexMinimumInstallerVersion]){ continue }
        }
        if ($IndexInstallerVersionLessThan -ne -1) {
            if ($VersionofScript -ge [System.Version]$RowData[$IndexInstallerVersionLessThan]){ continue }
        }
        if ($IndexMinimumEmu68Version -ne -1) {
            if ($EmuVersion -lt [System.Version]$RowData[$IndexMinimumEmu68Version]) { continue }
        }
        if ($IndexEmu68VersionLessThan -ne -1) {
            if ($EmuVersion -ge [System.Version]$RowData[$IndexEmu68VersionLessThan]) { continue }
        }
        if ($CSV -ne "OSVersionstoInstall" -and $IndexKickstartVersion -ne -1) {
            if ($KickstartVersion -notin $RowData[$IndexKickstartVersion].Split(',').Trim()){ continue }
        }
        if ($CSV -ne "IconSets" -and $IndexIconSet -ne -1) {
            $IconSetFound = $RowData[$IndexIconSet]
            if ($IconSetFound -ne "" -and $IconSetFound -ne "Any" -and $IconSetFound -ne $IconSet){ continue }
        }
               
        $RowHash = [System.Collections.Specialized.OrderedDictionary]::new($IndexesToKeep.Count)
        
        foreach ($i in $IndexesToKeep) {       
            if ($CSV -eq 'IconSets' -and $i -eq $IndexIconsDefaultInstall){
                $RowHash[$HeaderArr[$i]] = [bool]::Parse($RowData[$i])
            }
            else {
                $RowHash[$HeaderArr[$i]] = $RowData[$i]
            }       
        }

        [void]$Results.Add([PSCustomObject]$RowHash)
    }

    return $Results
}

