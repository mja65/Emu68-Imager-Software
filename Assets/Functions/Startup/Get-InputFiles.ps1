function Get-InputFiles { 
    param (

    )
   
    $PathtoGoogleDrivetouse = "$($Script:Settings.InputFiles.InputFileSpreadsheetURL)export?format=tsv&gid=$($Script:Settings.InputFiles.GID)"
    $client = New-Object System.Net.WebClient
    $client.Encoding = [System.Text.Encoding]::UTF8
    $client.Proxy = $null


    Write-InformationMessage -Message "Downloading latest version of input files"

    try {
        $rawContent = $client.DownloadString($PathtoGoogleDrivetouse)
        if ([string]::IsNullOrWhiteSpace($rawContent)) {
            throw "Download returned empty content."
        }
    }
    catch {
        Write-ErrorMessage -Message "CRITICAL ERROR: Failed to download data. Details: $($_.Exception.Message)" 
        return 
    }
    
    $Lines = $rawContent -split "`r?\n"
    
    $Script:InputCSVs = [PSCustomObject]@{}

    $CurrentVersion = [version]$Script:Settings.Version.ToString()
    
    $Lines.foreach({
        if ($_.StartsWith('#START_')) {
            $VarName = $_.Substring(7).Trim()
            $Headers = $null
            
            Write-InformationMessage -Message "Importing: $VarName"
            $Script:InputCSVs | Add-Member -MemberType NoteProperty -Name $VarName -Value ([PSCustomObject]@{
                Headers = $null
                Rows    = New-Object System.Collections.Generic.List[String[]]
            })
            $Target = $Script:InputCSVs.$VarName
        }
        elseif ($null -eq $Headers) {
            $Target.Headers = $_.Split(';').Trim() | Where-Object { $_ -ne "" }
            $Headers = $Target.Headers
            $MinVerIdx = [array]::IndexOf($Headers, 'MinimumInstallerVersion')
            $MaxVerIdx = [array]::IndexOf($Headers, 'InstallerVersionLessThan') 
            #Write-Host "DEBUG: Headers found: $($Headers -join ', ')" -ForegroundColor Cyan
            #Write-Host "DEBUG: MinVerIdx: $MinVerIdx | MaxVerIdx: $MaxVerIdx" -ForegroundColor Cyan                  
        }
        else {
            $Data = $_.Split(';')
            if ($Data.Count -gt 0) { 
                # Define these based on indices found
                $rawMin = if ($MinVerIdx -ge 0) { $Data[$MinVerIdx].Trim() } else { "" }
                $rawMax = if ($MaxVerIdx -ge 0) { $Data[$MaxVerIdx].Trim() } else { "" }

                $MinVer = if ([version]::TryParse($rawMin, [ref][version]$null)) { [version]$rawMin } else { [version]'0.0.0' }
                $MaxVer = if ([version]::TryParse($rawMax, [ref][version]$null)) { [version]$rawMax } else { [version]'99.9.9' }
                
                if ($CurrentVersion -ge $MinVer -and $CurrentVersion -lt $MaxVer) {
                    $Target.Rows.Add($Data)
                }
                # else {
                #     # This now uses the CLEAN version string, not the object
                #     Write-Host "DEBUG: DROPPED row. Range [$rawMin to $rawMax] vs Current: $CurrentVersion" -ForegroundColor Red
                # }
            }
        }   
    })
      
    return $true

}
