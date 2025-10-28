function Get-StartupFiles {
    param (
        
    )
      
    $StartupFiles = Import-Csv -Path $Script:Settings.StartupFilesCSV.Path -Delimiter ';'
    $PackagestoInstall = Get-PackagestoInstall -ListofFilestoCheck $StartupFiles
    $PackageName = $null

    if (-not ($PackagestoInstall)){
        Write-InformationMessage "All packages installed. Nothing to do."
        return $true
    } 

    Write-InformationMessage "Downloading required files"

    $DownloadLocation = "$($Script:Settings.TempFolder)\StartupFiles"
    if (-not (Test-Path $DownloadLocation)){
        $null = New-Item -Path $DownloadLocation -ItemType Directory
    }  

    $StartupFiles | Select-Object 'PackageName','FileDownloadName','SourceLocation','GithubRelease','GithubName','Hash','Source' -Unique | ForEach-Object {
        if ($PackagestoInstall.Contains($_.PackageName)){
            $HashtoCheck = $_.Hash
            $PathtoCheck = "$DownloadLocation\$($_.FileDownloadName)"
            if ((Confirm-FileExists -Pathtocheck $Pathtocheck -HashtoCheck $HashtoCheck) -eq $false){
                Write-InformationMessage "Downloading $($_.PackageName)"
                if ($_.Source -eq 'Web'){
                    if (-not (Get-AmigaFileWeb -URL $_.SourceLocation -LocationforDL "$($Script:Settings.TempFolder)\StartupFiles" -NameofDL $_.FileDownloadName)){
                        Write-ErrorMessage "Error downloading $($_.PackageName)! Cannot continue!"
                        return $false
                    }
                }
                elseif ($_.Source -eq 'Github'){
                    if (-not(Get-GithubRelease -GithubRepository $_.SourceLocation -GithubReleaseType $_.GithubReleaseType -Tag_Name $_.GithubRelease -Name $_.GithubName -LocationforDownload "$($Script:Settings.TempFolder)\StartupFiles\"-FileNameforDownload "$($_.FileDownloadName)")){
                        Write-ErrorMessage -Message "Error downloading $($_.PackageName)! Cannot continue!"
                        return $false
                    }
                }
            }   
        }
    }

    Write-InformationMessage "Downloads complete"
    
    $PackageName = $null
    
    $StartupFiles | ForEach-Object {
        if ($PackagestoInstall.Contains($_.PackageName)){
            if ($PackageName -ne $_.PackageName){
                Write-InformationMessage "Installing $($_.PackageName)"
            }
            $InputFile = "$($Script:Settings.TempFolder)\StartupFiles\$($_.FileDownloadName)"
            $LocationtoInstall = ".\$($_.LocationtoInstall)"                     
            if (-not (Test-Path $LocationtoInstall)){
                Write-InformationMessage "Folder $LocationtoInstall does not exist. Creating folder"
                $null = New-Item -Path $LocationtoInstall -ItemType Directory
            }
            Write-InformationMessage "Extracting file $($_.FilestoInstall)"
            if (-not (Expand-Archive -InputFile $InputFile -FiletoExtract $_.FilestoInstall -OutputDirectory $LocationtoInstall)){
                Write-ErrorMessage "Error extracting $($_.FilestoInstall)! Exiting"
                return $false
            }
            $PackageName = $_.PackageName
        }
    
    }

    return $true
}







    







