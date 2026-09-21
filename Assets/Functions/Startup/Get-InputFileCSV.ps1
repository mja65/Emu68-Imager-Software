function Get-InputFileCSV {
    param($CSV)

    # $CSV = "Packages" 

    $Target = $Script:InputCSVs.$CSV
    $HeaderArr = $Target.Headers
    $RowCount = $Target.Rows.Count
    
    $Results = [System.Collections.Generic.List[PSCustomObject]]::new($RowCount)
     
    $PackagePaths = @{}

    If ($CSV -in @("FolderstoAdd","PackagestoInstall","InfoFiles")){
        $Script:GUIActions.AvailablePackages.DefaultView.Where({
            $_.UserDefinableInstallPath -eq $true -and 
            ($_.PackageUserDrive -ne $_.PackageDefaultDrive -or $_.PackageUserPath -ne $_.PackageDefaultPath)
        }) | ForEach-Object {
            $PackagePaths[$_.PackageName] = @{
                PackageDefaultPath = $_.PackageDefaultPath
                PackageDefaultDrive= $_.PackageDefaultDrive
                PackageUserDrive   = $_.PackageUserDrive
                PackageUserPath    = $_.PackageUserPath
            }
        }
    }
    elseif ($CSV -in @("FileContentsModifyPath")){
        $Script:GUIActions.AvailablePackages.DefaultView | ForEach-Object {
            $PackagePaths[$_.PackageName] = @{
                PackageDefaultPath = $_.PackageDefaultPath
                PackageDefaultDrive= $_.PackageDefaultDrive
                PackageUserDrive   = $_.PackageUserDrive
                PackageUserPath    = $_.PackageUserPath
            }
        }
    }

    $IndexMinimumInstallerVersion = $HeaderArr.IndexOf("MinimumInstallerVersion")
    $IndexInstallerVersionLessThan = $HeaderArr.IndexOf("InstallerVersionLessThan")
    if ($CSV -in @("Emu68Versions", "PoseidonVersions", "NetworkStackVersions", "MUIVersions", "USBStackVersions", "GENETVersions")){
        $IndexEmu68VersionType = -1
       # $IndexPoseidonVersion = -1
       # $IndexNetworkStack = -1
       # $IndexMUIVersion = -1          
    } 
    else {
        $IndexEmu68VersionType = $HeaderArr.IndexOf("Emu68VersionType")
       # $IndexPoseidonVersion =  $HeaderArr.IndexOf("PoseidonVersion")
       # $IndexNetworkStack = $HeaderArr.IndexOf("NetworkStack")
       # $IndexMUIVersion = $HeaderArr.IndexOf("MUIVersion")
    }
    $IndexInclude = $HeaderArr.IndexOf("Include")
    $IndexKickstartVersion = $HeaderArr.IndexOf("KickstartVersion")
    $IndexIconSet = $HeaderArr.IndexOf("IconSet")
    $IndexDrivetoInstall = $HeaderArr.IndexOf("DrivetoInstall")
    $IndexLocationtoInstall = $HeaderArr.IndexOf("LocationtoInstall")
    $IndexDestinationPath = $HeaderArr.IndexOf("DestinationPath")
    $IndexRevisedPath = $HeaderArr.IndexOf("RevisedPath")
    $IndexRevisedDrive = $HeaderArr.IndexOf("RevisedDrive")
    $IndexPackage = $HeaderArr.IndexOf("PackageName")
    $IndexIconsDefaultInstall = $HeaderArr.IndexOf("IconsDefaultInstall")

    $IndexesToSkip = @(
        $IndexMinimumEmu68Version
        $IndexMinimumInstallerVersion
        $IndexInstallerVersionLessThan
        $IndexEmu68VersionLessThan
        $IndexInclude
        #$IndexNetworkStack 
        #$IndexPoseidonVersion 
        $IndexEmu68VersionType
        $IndexMUIVersion
        if ($CSV -ne "IconSets") { $IndexIconSet }    
        if ($CSV -ne "OSVersionstoInstall" -and $CSV -ne "ROMHashes") { $IndexKickstartVersion }
    ) | Where-Object { $_ -ne -1 } # Strip out columns that don't exist in this CSV

    $IndexesToKeep = [System.Collections.Generic.List[int]]::new($HeaderArr.Count)
    for ($i = 0; $i -lt $HeaderArr.Count; $i++) {
        if ($i -notin $IndexesToSkip) {
            $IndexesToKeep.Add($i)
        }
    }

    :rowloop foreach ($RowData in $Target.Rows) {    
        if ($IndexInclude -ne -1) {
            if ($RowData[$IndexInclude] -ne "TRUE"){ continue }
        }
        if ($IndexMinimumInstallerVersion -ne -1) {
            if ($Script:Settings.Version -lt [System.Version]$RowData[$IndexMinimumInstallerVersion]){ continue }
        }
        if ($IndexInstallerVersionLessThan -ne -1) {
            if ($Script:Settings.Version -ge [System.Version]$RowData[$IndexInstallerVersionLessThan]){ continue }
        }
        if ($IndexEmu68VersionType -ne -1) {
            if ((-not [string]::IsNullOrWhiteSpace($RowData[$IndexEmu68VersionType])) -and ($Script:GUIActions.Emu68VersionType -notin ($RowData[$IndexEmu68VersionType] -split ','))) { continue }            
        }
        # if ($IndexPoseidonVersion -ne -1) {
        #     if ((-not [string]::IsNullOrWhiteSpace($RowData[$IndexPoseidonVersion])) -and ($Script:GUIActions.PoseidonVersion -notin ($RowData[$IndexPoseidonVersion] -split ','))) { continue }

        # }
        # if ($IndexNetworkStack -ne -1) {
        #     if ((-not [string]::IsNullOrWhiteSpace($RowData[$IndexNetworkStack])) -and ($Script:GUIActions.NetworkStack -notin ($RowData[$IndexNetworkStack] -split ','))) { continue }
        # }
        # if ($IndexMUIVersion -ne -1) {
        #     if ((-not [string]::IsNullOrWhiteSpace($RowData[$IndexMUIVersion])) -and ($Script:GUIActions.MUIVersion -ne ($RowData[$IndexMUIVersion]))) { continue }     
        # }
        $RowDatatoUse = $RowData

        If ($CSV -in @("FolderstoAdd","PackagestoInstall","FileContentsModifyPath","InfoFiles")){
            $PackageName = $RowDatatoUse[$IndexPackage]
            If ($PackagePaths.ContainsKey($PackageName)) {
                $RevisedPackagePaths = $PackagePaths[$PackageName]
                If ($CSV -eq "FileContentsModifyPath"){
                    $RowDatatoUse[$IndexRevisedDrive] = $RevisedPackagePaths.PackageUserDrive
                    $RowDatatoUse[$IndexRevisedPath] = $RevisedPackagePaths.PackageUserPath          
                }
                else {
                    #Write-host "$($RevisedPackagePaths.PackageDefaultPath) $($RowDatatoUse[$IndexDestinationPath])"
                    if  (($RowDatatoUse[$IndexDestinationPath]).IndexOf($RevisedPackagePaths.PackageDefaultPath) -ge 0) {
                        #Write-Host "Wibble"
                        if ($RevisedPackagePaths.PackageUserPath -ne $RevisedPackagePaths.PackageDefaultPath){
                            If ($CSV -eq "FolderstoAdd"){
                                $RowDatatoUse[$IndexLocationtoInstall] = ($RowDatatoUse[$IndexDestinationPath]).replace($RevisedPackagePaths.PackageDefaultPath,$RevisedPackagePaths.PackageUserPath)
                            }
                            elseif ($CSV -eq "PackagestoInstall"){
                                $RowDatatoUse[$IndexDestinationPath] = ($RowDatatoUse[$IndexDestinationPath]).replace($RevisedPackagePaths.PackageDefaultPath,$RevisedPackagePaths.PackageUserPath)
                                  
                            }
                            elseif ($CSV -eq "InfoFiles"){
                                $RowDatatoUse[$IndexDestinationPath] = ($RowDatatoUse[$IndexDestinationPath]).replace($RevisedPackagePaths.PackageDefaultPath,$RevisedPackagePaths.PackageUserPath)
                            }
                        }
                        if ($RevisedPackagePaths.PackageUserDrive -ne $RevisedPackagePaths.PackageDefaultDrive){
                            $RowDatatoUse[$IndexDrivetoInstall] = $RevisedPackagePaths.PackageUserDrive                    
                        }
                    }
                }
            }
        }
        if ($CSV -ne "OSVersionstoInstall" -and $CSV -ne "ROMHashes" -and $CSV -notin @("Emu68Versions", "PoseidonVersions", "NetworkStackVersions", "MUIVersions") -and $IndexKickstartVersion -ne -1) {
            if ($Script:GUIActions.KickstartVersiontoUse -notin $RowDatatoUse[$IndexKickstartVersion].Split(',').Trim()){ continue }
        }
        if ($CSV -ne "IconSets" -and $IndexIconSet -ne -1) {
            $IconSetFound = $RowDatatoUse[$IndexIconSet]
            if ($IconSetFound -ne "" -and $IconSetFound -ne "Any" -and $IconSetFound -ne $Script:GUIActions.SelectedIconSet){ continue }
        }
               
        $RowHash = [System.Collections.Specialized.OrderedDictionary]::new($IndexesToKeep.Count)
        
        foreach ($i in $IndexesToKeep) {       
            if ($CSV -eq 'IconSets' -and $i -eq $IndexIconsDefaultInstall){
                $RowHash[$HeaderArr[$i]] = [bool]::Parse($RowDatatoUse[$i])
            }
            else {
                $RowHash[$HeaderArr[$i]] = $RowDatatoUse[$i]
            }       
        }

        [void]$Results.Add([PSCustomObject]$RowHash)
    }

    return $Results
}

