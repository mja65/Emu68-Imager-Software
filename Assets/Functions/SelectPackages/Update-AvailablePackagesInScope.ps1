function Update-AvailablePackagesInScope {
    param (
        
    )
 
    $NetworkPackages = Get-ConfigurablePackages -NetworkStackPackages
    $USBPackages = Get-ConfigurablePackages -USBStackPackages
    
    $networkPackageTypes = 'Selectable Package - Network - DefaultInstall', 'Selectable Package - Network'
    $usbPackageTypes     = 'Selectable Package - USB - DefaultInstall', 'Selectable Package - USB'
    $Script:GUIActions.AvailablePackages | ForEach-Object {
        $type = $_.PackageType
        $isNetwork = $type -in $networkPackageTypes
        $isUsb     = $type -in $usbPackageTypes
        if ($isNetwork -or $isUsb) {
            $inScope = ($isNetwork -and $_.PackageName -in $NetworkPackages) -or ($isUsb -and $_.PackageName -in $USBPackages)
            $_.PackageinScope = $inScope
        }
    }
                    
}
    