function Get-Emu68ImagerCurrentVersion {
    param (
        $GithubRelease

    )
    
    # $GithubRelease = "https://api.github.com/repos/mja65/Emu68Imager2/releases"
    
    $client = [System.Net.Http.HttpClient]::new()
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("PowerShellHttpClient")
    $GithubDetails = $null
    
    $Counter = 0
    $IsSuccess = $null


    do {
        $GithubDetails = $client.GetStringAsync($GithubRelease).Result
        if ($GithubDetails){
            $GithubDetails = $GithubDetails | ConvertFrom-Json 
            $IsSuccess = $true  
        }
        else {
            Start-Sleep -Seconds 3
            $IsSuccess = $false
        }
        $Counter ++              
    } until (
        $IsSuccess -eq $true -or $Counter -eq 3 
    )

    if ($GithubDetails) {
        foreach ($line in $GithubDetails) {
            $line.tag_name = $line.tag_name -replace '^v', '' # Remove leading v if it exists
        }             
        $GithubDetails = $GithubDetails | Where-Object {$_.prerelease.tostring() -eq "False"} | Sort-Object -Property "tag_name" -Descending | Select-Object -First 1
        $VersionFound = ($GithubDetails | Select-Object -First 1).tag_name      
               
        if([system.version]$VersionFound -gt $Script:Settings.Version){
            $VersionInformationtoReport = "Version found on server: $VersionFound. Your version of Emu68 Imager needs updating!"

    
        }
        else {
            $VersionInformationtoReport = "Version of Emu68 Imager on server: $VersionFound. Your version of Emu68 Imager is up to date."
        }
    }
    else {
        $VersionInformationtoReport  = "Version of Emu68 Imager on server: Could not access Github!"
    }
    
    return $VersionInformationtoReport 
}
