function Confirm-NoChangedInstallPaths {
    param (

    )
    ForEach ($Package in $Script:GUIActions.AvailablePackages){
        if ($Package.PackageUserDrive -ne $Package.PackageDefaultDrive -or $Package.PackageDefaultPath -ne $Package.PackageUserPath){
            return $false
        } 
    }

    return $true
        
}