function Get-NewInstallPathFolders {
    param (
    )
    $allSubPaths = $Script:GUIActions.AvailablePackages.Where({ $_.PackageDefaultPath -ne $_.PackageUserPath -or $_.PackageUserDrive -ne $_.PackageDefaultDrive }) | ForEach-Object {
        
        $PathtoSplit = $_.PackageUserPath
        $parts = $PathtoSplit -split '[/\\]' | Where-Object { $_ }
        for ($i = 1; $i -le $parts.Count; $i++) {
            $relativePath = $parts[0..($i - 1)] -join [System.IO.Path]::DirectorySeparatorChar
            [PSCustomObject]@{
                PackageName      = $_.PackageName      # or $package.Name depending on your object property
                DrivetoInstall   = $_.PackageUserDrive
                LocationtoInstall = $relativePath 
                CreateInfoFile   = $true  # or $true / $false depending on your logic
            }            
        }
    }

    return $allSubPaths
    
}

