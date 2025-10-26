function Get-PackagestoInstall {
    param (
        $ListofFilestoCheck
    )
    
    # $ListofFilestoCheck = Import-Csv -Path $Script:Settings.StartupFilesCSV.Path -Delimiter ';'

    $ListofPackages = $ListofFilestoCheck | Select-Object 'PackageName' -Unique

    $PackagestoUpdate = @()

    foreach ($Package in $ListofPackages) {
        $PackageUptoDate = $true
        $CurrentPackageCheckComplete = $false
        Write-InformationMessage -Message "Starting check of Package: $($Package.PackageName)"
        $ListofFilestoCheck | Where-Object {$_.PackageName -eq $Package.PackageName} | ForEach-Object {
            if ($CurrentPackageCheckComplete -eq $false){
                if ($_.FileHash -ne ""){
                    Write-InformationMessage "Checking file: $($_.FilestoInstall)"
                    $PathtoInstallFile = ".\$($_.LocationtoInstall)$($_.FilestoInstall)"   
                    if (-not (Test-Path $PathtoInstallFile)){
                        $PackagestoUpdate += $Package.PackageName
                        $PackageUptoDate = $false
                        $CurrentPackageCheckComplete = $true
                        Write-InformationMessage -Message "$($Package.PackageName) does not exist! Package will be installed."
                    }
                    else {                      
                        $HashtoCheck = (Get-FileHash -Path $PathtoInstallFile -Algorithm MD5).hash
                      #  Write-Debug "Hash recorded: $($_.FileHash) Hash to check: $HashtoCheck "
                        if ($HashtoCheck -ne $_.FileHash){
                            $PackagestoUpdate += $Package.PackageName
                            Write-InformationMessage -message "$($FiletoCheck.PackageName) is out of date! Package will be reinstalled."
                            $CurrentPackageCheckComplete = $true
                            $PackageUptoDate = $false
                        }
                    }   
                }
            } 
        }
        if ($PackageUptoDate -eq $true){
            Write-InformationMessage -Message "$($Package.PackageName) is up to date"
        }
    }

    return $PackagestoUpdate
}
