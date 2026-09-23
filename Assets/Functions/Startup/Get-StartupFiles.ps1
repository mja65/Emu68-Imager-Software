function Get-StartupFiles {
    param (
        
    )
    
    if (-not (Test-path $Script:ExternalProgramSettings.SevenZipFilePath)){
        Write-ErrorMessage -Message "7z is missing! Either redownload and/or re-extract Emu68 Imager"
        return $false
    }

    $AminetMirrors = (Get-InputFileCSV -CSV 'AminetMirrors')

    $DownloadLocation = join-path $Script:Settings.TempFolder "StartupFiles"
   
    if (Test-Path -Path $DownloadLocation -pathType Container){
        Remove-Item -Path $DownloadLocation -Force -Recurse -ErrorAction SilentlyContinue
    }

    $null = New-Item -Path $DownloadLocation -ItemType Directory

    $PackageName = $null
    $PackagesNeedUpdating = $false
    $LogPathStandardOutput = join-path $Script:Settings.TempFolder "LogStd.txt"
   
    foreach ($Line in (Get-InputFileCSV -CSV 'StartupFiles')){
    
        If ($PackageName -ne $Line.PackageName){
            $PackageUptoDate = $true
            $PackageUpdated = $false
            Write-InformationMessage -Message "Starting check of Package: $($Line.PackageName)" -NewLineBefore
        }
        $PackageName = $Line.PackageName
        if ($PackageUpdated -eq $true){continue}
        write-informationMessage -Message "Checking file: $($Line.FilestoCheck)"
        $PathtoExtract = join-pathmulti "." $Line.LocationtoInstall
        $PathtoFiletoCheck = join-pathmulti $PathtoExtract $Line.FilestoCheck
        if (-not (Test-Path $PathtoFiletoCheck)){
            $PackageUptoDate = $false
            $PackagesNeedUpdating = $true
            Write-InformationMessage -Message "$($Line.PackageName) does not exist! Package will be installed." -NewLineBefore
        }
        If ($PackageUptoDate -eq $true){
            $HashtoCheck = (Get-FileHash -Path $PathtoFiletoCheck -Algorithm MD5).hash
            if ($HashtoCheck -ne $Line.FileHash){
                $PackageUptoDate = $false
                $PackagesNeedUpdating = $true
                Write-InformationMessage -message "$($Line.PackageName) is out of date! Package will be reinstalled." -NewLineBefore
            }
        }
        If ($PackageUptoDate -eq $false){
            write-informationMessage -Message "Downloading required files"
            if (-not (Test-Path $DownloadLocation)){
                $null = New-Item -Path $DownloadLocation -ItemType Directory
            }  
            $DownloadLocation = join-pathMulti $Script:Settings.TempFolder "StartupFiles" $Line.FileDownloadName
            if ($Line.Source -eq 'Web'){
                #Write-host "URL: $($Line.SourceLocation) LocationforDL: $DownloadLocation"
                if (-not (Get-AmigaFileWeb -AminetMirrors $AminetMirrors -URL $Line.SourceLocation -LocationforDL $DownloadLocation)){
                    Write-ErrorMessage -Message "Error downloading $($Line.PackageName)! Cannot continue!"
                    return $false
                }
            }
            elseif ($Line.Source -eq 'Github'){
                $DownloadURL = Get-GithubRelease -GithubRepository $Line.SourceLocation -GithubReleaseType $Line.GithubReleaseType -Tag_Name $Line.GithubRelease -Name $Line.GithubName -GithubNameExclude $Line.GithubNameExclude -GithubSortTagPrefix $Line.GithubSortTagPrefix -GithubSortSemanticVersion $Line.GithubSortSemanticVersion -MinimumPublishedDate $Line.GithubMinimumPublishedDate
                if (-not($DownloadURL)){
                    Write-ErrorMessage -Message "Error finding Github release for $($Line.PackageName)! Cannot continue!"
                    return $false
                }           
                if (-not(Get-AmigaFileWeb -URL $DownloadURL -LocationforDL $DownloadLocation -NumberofAttempts 3 -RunParallel $false)){
                    Write-ErrorMessage -Message "Error downloading $($Line.PackageName)! Cannot continue!"
                    return $false
                }
            }
            if ((Get-FileHash -Path $DownloadLocation  -Algorithm MD5).hash -ne $Line.Hash){
                Write-ErrorMessage -Message "File hashes do not match. Cannot continue!"
                $null = Remove-Item -Path $DownloadLocation 
                return $false 
            }
            else {
                Write-InformationMessage -Message "Extracting $($Line.PackageName)"
                $OutputMessage = & $Script:ExternalProgramSettings.SevenZipFilePath "x" "-o$PathtoExtract" "$DownloadLocation" "-y" 2>&1                       
                if ($LASTEXITCODE -ne 0) {
                    Write-ErrorMessage -Message "Error extracting $DownloadLocation! Exiting" 
                    $OutputMessage | Out-File -FilePath (join-path $Script:Settings.LogFolder "SevenZipError.txt") -Encoding UTF8 
                    return $false
                }
                $PackageUpdated = $true
            }            
        }
    }
      
    if ($PackagesNeedUpdating -eq $false){
        write-informationMessage -Message "All packages installed. Nothing to do." -NewLineBefore
        return $true
    } 
    else {
        if (Test-Path ".\Programs\UnAdf\include"){
            remove-item ".\Programs\UnAdf\include" -recurse -force -ErrorAction SilentlyContinue
        }
        if (Test-Path ".\Programs\UnAdf\doc"){
            remove-item ".\Programs\UnAdf\doc" -recurse -force -ErrorAction SilentlyContinue
            write-informationMessage -Message "All required packages updated." -NewLineBefore
            return $true             
        } 
    }

    return $true
}
