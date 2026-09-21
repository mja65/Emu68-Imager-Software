function Get-SelectablePackages {
    param (
        [Switch]$PackagesOnly,
        [Switch]$KeepInstallStatus
    )

    $ExistingPackageDetails = @{}

    If ($KeepInstallStatus){    
        $Script:GUIActions.AvailablePackages.Where({ ($_.PackageNameUserSelected -ne $_.PackageNameDefaultInstall) -or 
            ($_.UserDefinableInstallPath -eq $true -and ($_.PackageUserDrive -ne $_.PackageDefaultDrive -or $_.PackageUserPath -ne $_.PackageDefaultPath))
        }) | ForEach-Object {
            $ExistingPackageDetails[$_.PackageName] = @{
                PackageNameUserSelected = $_.PackageNameUserSelected
                PackageDefaultPath = $_.PackageDefaultPath
                PackageDefaultDrive= $_.PackageDefaultDrive
                PackageUserDrive   = $_.PackageUserDrive
                PackageUserPath    = $_.PackageUserPath
            }
        }                        
    }
     
    $Script:GUIActions.AvailablePackages.Clear()

    $NetworkPackages = Get-ConfigurablePackages -NetworkStackPackages
    $USBPackages = Get-ConfigurablePackages -USBStackPackages

    $basePackageTypes    = 'Selectable OS', 'Selectable OS - DefaultInstall', 'Selectable Package', 'Selectable Package - DefaultInstall'
    $networkPackageTypes = 'Selectable Package - Network - DefaultInstall', 'Selectable Package - Network'
    $usbPackageTypes     = 'Selectable Package - USB - DefaultInstall', 'Selectable Package - USB'

    $Packages = Get-InputFileCSV -CSV 'Packages' | ForEach-Object {
        $type = $_.PackageType
        $isBase    = $type -in $basePackageTypes
        $isNetwork = $type -in $networkPackageTypes
        $isUsb     = $type -in $usbPackageTypes
        if ($isBase -or $isNetwork -or $isUsb) {
            $inScope = $isBase -or ($isNetwork -and $_.PackageName -in $NetworkPackages) -or ($isUsb -and $_.PackageName -in $USBPackages)
            $_ | Add-Member -NotePropertyName 'PackageinScope' -NotePropertyValue $inScope -PassThru
        }
    } | Sort-Object -Property PackageNameFriendlyName
            
    foreach ($line in $Packages) {
        $PackageNameDefaultInstall = $Line.PackageType -in  @('Selectable OS - DefaultInstall', 'Selectable Package - DefaultInstall', "Selectable Package - Network - DefaultInstall", "Selectable Package - USB - DefaultInstall")
        If ($ExistingPackageDetails.ContainsKey($Line.PackageName)){
            $PackageDetailstoUse = $ExistingPackageDetails[$Line.PackageName]
            $PackageNameUserSelected = $PackageDetailstoUse.PackageNameUserSelected 
            $PackageDefaultPath = $PackageDetailstoUse.PackageDefaultPath
            $PackageDefaultDrive = $PackageDetailstoUse.PackageDefaultDrive
            $PackageUserDrive = $PackageDetailstoUse.PackageUserDrive
            $PackageUserPath = $PackageDetailstoUse.PackageUserPath
        }
        else {
            $PackageNameUserSelected = $PackageNameDefaultInstall
            $PackageDefaultPath = $line.PackageDefaultPath
            $PackageDefaultDrive = $line.PackageDefaultDrive
            $PackageUserDrive = $line.PackageDefaultDrive
            $PackageUserPath =  $line.PackageDefaultPath
        }

        $RowData = @(
            $PackageNameUserSelected
            $PackageNameDefaultInstall
            $line.PackageName
            $line.PackageType           
            $line.PackageNameFriendlyName
            $line.PackageNameGroup
            $line.PackageNameDescription
            $line.PackageURL
            $line.PackageAuthor
            $line.UserDefinableInstallPath
            $PackageDefaultDrive
            $PackageUserDrive 
            $PackageDefaultPath
            $PackageUserPath
            [bool]$line.PackageinScope 
        )
        [void]$Script:GUIActions.AvailablePackages.Rows.Add($RowData)
    }

    $Script:GUIActions.AvailablePackages.DefaultView.RowFilter = "PackageinScope = true"

    If (-not ($PackagesOnly)){ 
        Write-AvailableIconsets

    }

    $Script:GUICurrentStatus.AvailablePackagesNeedingGeneration = "FALSE"
   
}

