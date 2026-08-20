function Get-PackagesfromInternet {
    param (
        
        $ListofPackagestoDownload

    )
     
    #$ListofPackagestoInstall = Get-InputCSVs -PackagestoInstall | Where-Object {(($_.KickstartVersion -eq $Script:GUIActions.KickstartVersiontoUse) -and ($_.IconsetName -eq "" -or $_.IconsetName -eq $Script:GUIActions.SelectedIconSet))} 
    #$ListofPackagestoDownload = $ListofPackagestoInstall | Where-Object {(($_.Source -eq "Github") -or  ($_.Source -eq "Web") -or ($_.Source -eq "Web - SearchforPackageAminet") -or ($_.Source -eq "Web - SearchforPackageWHDLoadWrapper"))} | Select-Object 'Source','GithubName','GithubReleaseType','SourceLocation','BackupSourceLocation','FileDownloadName','PerformHashCheck','Hash','UpdatePackageSearchTerm','UpdatePackageSearchResultLimit', 'UpdatePackageSearchExclusionTerm','UpdatePackageSearchMinimumDate' -Unique 
    #$ListofPackagestoDownload = $ListofPackagestoDownloadfromInternet | Where-Object {$_.FileDownloadName -eq 'IBrowse-OS3.lha'}
    
    if (-not (Test-Path -Path $Settings.WebPackagesDownloadLocation)){
        $null = New-Item -Path $Settings.WebPackagesDownloadLocation -ItemType Directory
    }
     
    $Script:Settings.TotalNumberofSubTasks = $ListofPackagestoDownload.Count 
    $Script:Settings.CurrentSubTaskNumber = 1
    
    foreach ($Line in $ListofPackagestoDownload){
        $Script:Settings.CurrentSubTaskName = "Processing $($line.FileDownloadName)"
        $UseBackupServerImmediately =$false
        Write-StartSubTaskMessage 
        if ($Line.Source -eq "Github"){
            $GithubDownloadLocation = $Settings.WebPackagesDownloadLocation
            $GithubDownloadPath = Join-Path $GithubDownloadLocation $Line.FileDownloadName
            $ResolvedGithubDigest = $null
            #Write-debug "GithubRepository: $($line.SourceLocation) GithubReleaseType: $($Line.GithubReleaseType) Tag_Name: $($line.GithubRelease) Name: $($line.GithubName) LocationforDownload: $("$GithubDownloadLocation\") FileNameforDownload: $($line.FileDownloadName)"
            $GithubDownloadSucceeded = Get-GithubRelease -GithubRepository $line.SourceLocation -GithubReleaseType $Line.GithubReleaseType -Tag_Name $line.GithubRelease -Name $line.GithubName -LocationforDownload "$GithubDownloadLocation\" -FileNameforDownload "$($line.FileDownloadName)" -ResolvedDigest ([ref]$ResolvedGithubDigest)

            if ("$($Line.PerformHashCheck)" -eq 'TRUE' -and [string]::IsNullOrWhiteSpace($ResolvedGithubDigest)) {
                Write-InformationMessage -Message "GitHub did not publish a digest for $($line.GithubName); the online asset cannot be verified"
                $GithubDownloadSucceeded = $false
            }

            if (-not $GithubDownloadSucceeded -and (Test-Path -LiteralPath $GithubDownloadPath -PathType Leaf)) {
                Remove-Item -LiteralPath $GithubDownloadPath -Force
            }

            if (-not (Confirm-GithubPackageDownload `
                -DownloadPath $GithubDownloadPath `
                -ExpectedHash $ResolvedGithubDigest `
                -BackupSourceLocation $Line.BackupSourceLocation `
                -FallbackExpectedHash $Line.Hash)) {
                Write-ErrorMessage -Message "Error downloading the official GitHub release asset $($line.GithubName)! Cannot continue!"
                return $false
            }

        }
        elseif (($Line.Source -eq "Web") -or ($Line.Source -eq "Web - SearchforPackageAminet") -or ($Line.Source -eq "Web - SearchforPackageWHDLoadWrapper")) {
            $SourceLocation = $null
            $PerformHashCheckFlag = $false
            $DownloadFileFlag = $true
            if ($Line.Source -eq "Web"){
                $SourceLocation = $line.SourceLocation
                if ($line.PerformHashCheck -eq $true){
                    $PerformHashCheckFlag = $true
                }
            }
            elseif ($Line.Source -eq "Web - SearchforPackageAminet"){
                $SourceLocation = Find-LatestAminetPackage -PackagetoFind $Line.UpdatePackageSearchTerm -Exclusion $line.UpdatePackageSearchExclusionTerm -DateNewerthan $line.UpdatePackageSearchMinimumDate -Architecture 'm68k-amigaos' 
            }
            elseif ($Line.Source -eq "Web - SearchforPackageWHDLoadWrapper") {
                $SourceLocation = (Find-WHDLoadWrapperURL -SearchCriteria 'WHDLoadWrapper' -ResultLimit '10') 
            }
            if (-not ($SourceLocation)){
                $UseBackupServerImmediately = $true
            }
            if (test-path "$($Settings.WebPackagesDownloadLocation)\$($line.FileDownloadName)"){
                Write-InformationMessage -Message "Download of $($line.FileDownloadName) already completed"
                if ($PerformHashCheckFlag -eq $true){
                    if (-not (Compare-FileHash -FiletoCheck "$($Settings.WebPackagesDownloadLocation)\$($line.FileDownloadName)" -HashtoCheck $line.Hash)){
                        Write-InformationMessage -Message "Error in previously downloaded file $($line.FileDownloadName). File will be removed and re-downloaded"
                        $null=Remove-Item -Path "$($Settings.WebPackagesDownloadLocation)\$($line.FileDownloadName)" -Force 
                    }
                    else {
                        $DownloadFileFlag = $false
                    }
                }
                else {
                    $DownloadFileFlag = $false
                }
            }
            if ($DownloadFileFlag -eq $true){
                if (-not (Get-AmigaFileWeb -URL $SourceLocation -BackupURL $line.BackupSourceLocation -NameofDL $line.FileDownloadName -LocationforDL $Script:Settings.WebPackagesDownloadLocation -UseBackupServerImmediately $UseBackupServerImmediately)){
                    Write-ErrorMessage -Message 'Unrecoverable error with download(s)!'
                    exit
                }
                if ($PerformHashCheckFlag -eq $true){
                    if (-not (Compare-FileHash -FiletoCheck "$($Settings.WebPackagesDownloadLocation)\$($line.FileDownloadName)" -HashtoCheck $line.Hash)){
                        Write-ErrorMessage -Message 'Error in downloaded packages! Unable to continue!'
                        Write-InformationMessage -Message ("Deleting package $PackageDownloadsLocation\$($line.FileDownloadName)")
                        $null=Remove-Item -Path "$($Settings.WebPackagesDownloadLocation)\$($line.FileDownloadName)" -Force 
                        exit
                    }
                }     
            }
            else {
                Write-InformationMessage -Message "No Download Required"
            }
        }

        if ($Line.Source -in @(
                'Github',
                'Web',
                'Web - SearchforPackageAminet',
                'Web - SearchforPackageWHDLoadWrapper'
            ) -and
            -not (Test-PackageArchiveStructure `
                -ArchivePath (Join-Path $Settings.WebPackagesDownloadLocation $Line.FileDownloadName) `
                -RequiredArchiveEntries $Line.RequiredArchiveEntries)) {
            $RejectedArchivePath = Join-Path $Settings.WebPackagesDownloadLocation $Line.FileDownloadName
            if (Test-Path -LiteralPath $RejectedArchivePath -PathType Leaf) {
                Remove-Item -LiteralPath $RejectedArchivePath -Force
            }
            Write-ErrorMessage -Message "The downloaded package $($line.FileDownloadName) does not contain the required files! Cannot continue!"
            return $false
        }

        $Script:Settings.CurrentSubTaskNumber ++
    }

    return $true
}
