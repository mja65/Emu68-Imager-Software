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
        Write-StartSubTaskMessage 
        if ($Line.Source -eq "Github"){
            $GithubDownloadLocation = $Settings.WebPackagesDownloadLocation
            if (-not(Get-GithubRelease -GithubRepository $line.SourceLocation -GithubReleaseType $Line.GithubReleaseType -Tag_Name $line.GithubRelease -Name $line.GithubName -LocationforDownload "$GithubDownloadLocation\" -FileNameforDownload "$($line.FileDownloadName)")){
                Write-ErrorMessage -Message "Error downloading $($line.GithubName)! Cannot continue!"
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
                #Error reported through function
                exit
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
                if (-not (Get-AmigaFileWeb -URL $SourceLocation -BackupURL $line.BackupSourceLocation -NameofDL $line.FileDownloadName -LocationforDL $Script:Settings.WebPackagesDownloadLocation)){
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
        $Script:Settings.CurrentSubTaskNumber ++
    }

}
