function Get-ConfigurablePackages {
    param (
        [switch]$Emu68Packages,
        [switch]$USBStackPackages,
        [switch]$GenetPackages,
        [switch]$PoseidonPackages,
        [switch]$NetworkStackPackages,
        [switch]$MUIPackages
      
    )

    If ($Emu68Packages) {
        if (-not $Script:GUIActions.Emu68VersionType) { return }
        $CSVName = "Emu68Versions"
        $FilterBlock = {
            $Script:GUIActions.Emu68VersionType -in ($_.Emu68VersionType -split '\s*,\s*') 
        }    
    }
    
    If ($USBStackPackages) {
        if ($Script:GUIActions.EnableUSBStack -eq $false) { return }
        $CSVName = "USBStackVersions"  
        $FilterBlock = {
            $Script:GUIActions.Emu68VersionType -in ($_.Emu68VersionType -split '\s*,\s*') -and 
            $Script:GUIActions.PoseidonVersion -in ($_.PoseidonVersion -split '\s*,\s*')
        }    
    }
  
    If ($GenetPackages) {
        if (-not $Script:GUIActions.NetworkStack) { return }  
        $CSVName = "genetVersions"
        $FilterBlock = {
            $Script:GUIActions.Emu68VersionType -in @($_.Emu68VersionType -split '\s*,\s*') -and 
            $Script:GUIActions.NetworkStack -in @($_.NetworkStack -split '\s*,\s*') 
        }
    }

    If ($PoseidonPackages) {
        if (-not $Script:GUIActions.PoseidonVersion) { return }
        $CSVName = "PoseidonVersions"        
        $FilterBlock = {
            $Script:GUIActions.PoseidonVersion -in ($_.PoseidonVersion -split '\s*,\s*')
        }
     }
    
    If ($NetworkStackPackages) {
        if (-not $Script:GUIActions.NetworkStack) { return }  
        if ($Script:GUIActions.NetworkStack -eq "Roadshow - Demo") {
            If ($Script:GUICurrentStatus.RoadshowUserFiles){
                $NetworkStacktoUse = "Roadshow - Full"
            }
            else {
                $NetworkStacktoUse = "Roadshow - Demo"
            }
        }
        elseif ($Script:GUIActions.NetworkStack -eq "Miami - Demo"){
            if ($Script:GUICurrentStatus.MiamiUserFiles){
                $NetworkStacktoUse = "Miami - Full"
            }
            else {
                $NetworkStacktoUse = "Miami - Demo"
            }    
        }
        else {
            $NetworkStacktoUse = $Script:GUIActions.NetworkStack             
        }
            
        $CSVName = "NetworkStackVersions"
        $FilterBlock = {
            $Script:GUIActions.Emu68VersionType -in ($_.Emu68VersionType -split '\s*,\s*') -and 
            $NetworkStacktoUse -in ($_.NetworkStack -split '\s*,\s*')
        }
    }

    If ($MUIPackages) { 
        if (-not $Script:GUIActions.MUIVersion) { return }
        $CSVName = "MUIVersions"
        $FilterBlock = {
            $Script:GUIActions.MUIVersion -in ($_.MUIVersion -split '\s*,\s*')
        }
        
    }

    $CsvData = Get-InputFileCSV -CSV $CSVName
    $MatchingRows = $CsvData.Where($FilterBlock)
    $Packages = $MatchingRows.Packages -split '\s*,\s*' | Where-Object { $_ }

    return $Packages
      
}
