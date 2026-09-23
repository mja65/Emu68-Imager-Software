function Find-LatestAminetPackage {
    param (
        $PackagetoFind,
        $Exclusion,
        $DateNewerthan,
        $Architecture
    )
      
    $AminetMirrors =  Get-InputFileCSV -CSV 'AminetMirrors'
    $IsSuccess = $false
    $AminetURL='http://aminet.net'
    Write-InformationMessage -Message "Searching for: $PackagetoFind"
    foreach ($Mirror in $AminetMirrors){
        Write-InformationMessage -Message "Using mirror: $($Mirror.MirrorURL) `($($Mirror.Type)`)"
        $URLBase=$Mirror.Type+'://'+$Mirror.MirrorURL
        $URL = ($URLBase+'/search?name='+$PackagetoFind+'&o_date=newer&date='+$DateNewerthan+'&arch[]='+$Architecture)
        try {
            $ListofAminetFiles = Invoke-WebRequest $URL -UseBasicParsing # -AllowInsecureRedirect Powershell 5 compatibility
            $IsSuccess = $true    
            break
        }
        catch {
            Write-InformationMessage -message "Download failed! Trying next mirror"
        }

    }
  
    if ($IsSuccess -ne $true){
        Write-ErrorMessage -Message "Could not access Aminet to find package! Unrrecoverable error!"
        return   
    }

    foreach ($Line in $ListofAminetFiles.Links) {      
    if (!$Exclusion) {
        if (($line -match ('.lha'))){
            Write-InformationMessage -Message "Found $($line.href)"
            return ($AminetURL+$line.href)
       }     
    }
    else {
    }
        if (($line -match ('.lha')) -and (-not ($line -match $Exclusion))){
            Write-InformationMessage -Message "Found $($line.href)"
            return ($AminetURL+$line.href)
       }       
    }
    Write-ErrorMessage -Message "Could not find package! Unrrecoverable error!"
    return                 
}