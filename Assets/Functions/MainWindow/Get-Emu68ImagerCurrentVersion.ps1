function Get-Emu68ImagerCurrentVersion {
    param (
        $GithubRelease

    )
    
    # $GithubRelease = "https://api.github.com/repos/mja65/Emu68-Imager-Software/releases"
    
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

        $GithubLatest = $GithubDetails | Where-Object {$_.prerelease.tostring() -eq "False"} |Sort-Object { [version]($_.tag_name -replace '^v') } -Descending | Select-Object -First 1
        $VersionFound = ($GithubLatest.tag_name -replace '^v')
          
        if([system.version]$VersionFound -gt $Script:Settings.Version){

            $VersionInformationtoReport = [PSCustomObject]@{
                TexttoReport  = "Version found on server: $VersionFound. Your version of Emu68 Imager needs updating!"
                IsUptoDate = $false
            }
            
        }
        else {
            
            $VersionInformationtoReport = [PSCustomObject]@{
                TexttoReport  = "Version of Emu68 Imager on server: $VersionFound. Your version of Emu68 Imager is up to date."
                IsUptoDate = $true
            }

        }
    }
    else {
        
        $VersionInformationtoReport = [PSCustomObject]@{
            TexttoReport  = "Version of Emu68 Imager on server: Could not access Github!"
            IsUptoDate = $null
        }      

    }
    
    return $VersionInformationtoReport 
}
