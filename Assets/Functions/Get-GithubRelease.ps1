function Get-GithubRelease {
    param (
        $GithubRepository,
        $GithubReleaseType,
        $Tag_Name,
        $Name,
        $LocationforDownload,
        $FileNameforDownload
    )
  
    # $LocationforDownload = "E:\PiStorm\"
    
    # $GithubRepository = "https://api.github.com/repos/michalsc/Emu68-tools/releases"
    # $GithubReleaseType = 'nightly'
    # $Tag_Name = ""
    # $Name = "Emu68-tools"
    # $FileNameforDownload = "Emu68-Tools.zip"
    
    # $GithubRepository = "https://api.github.com/repos/michalsc/Emu68/releases"
    # $GithubReleaseType = 'Release'
    # $Tag_Name = ""
    # $Name = "Emu68-pistorm32lite."
    # $FileNameforDownload = "Emu68PiStorm32lite.zip"
    
    
    if (-not(Test-Path (split-path $LocationforDownload))){
        $null = New-Item -Path (split-path $LocationforDownload) -Force -ItemType Directory
    }

    $PathforDownload = "$LocationforDownload$FileNameforDownload"

    Write-InformationMessage -Message "Retrieving Github information for: $GithubRepository"

    $client = [System.Net.Http.HttpClient]::new()
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("PowerShellHttpClient")
    $GithubDetails = $null
    
    $Counter = 0
    $IsSuccess = $null
           
    do {
        $GithubDetails = $client.GetStringAsync($GithubRepository).Result | ConvertFrom-Json
        if ($GithubDetails){
            $IsSuccess = $true  
        }
        else {
            Write-InformationMessage -message 'Download failed! Retrying in 3 seconds'
            Start-Sleep -Seconds 3
            $IsSuccess = $false
        }
        $Counter ++              
    } until (
        $IsSuccess -eq $true -or $Counter -eq 3 
    )

    if ( -not $GithubDetails){
        Write-ErrorMessage 'Error accessing Github! Quitting Program'
        exit
    }  

    If (($GithubReleaseType -eq "Release") -or ($GithubReleaseType -eq "Release-NoArchive")){
        if ($Tag_Name){
            $GithubDetails_ForDownload = $GithubDetails | Where-Object { $_.tag_name -eq $Tag_Name } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name }             
        }
        else {
            $GithubDetails_Sorted = $GithubDetails | Where-Object { $_.tag_name -ne 'nightly' -and ($_.draft).tostring() -eq 'False' -and ($_.prerelease).tostring() -eq 'False' -and ($_.name).tostring() -notmatch 'Release Candidate'} | Sort-Object -Property 'tag_name' -Descending | Select-Object -ExpandProperty assets 
            $GithubDetails_ForDownload = $GithubDetails_Sorted  | Where-Object { $_.name -match $Name } | Select-Object -First 1
        }
    }
    elseif ($GithubReleaseType -eq "nightly"){
        $GithubDetails_Sorted = $GithubDetails | Where-Object { $_.tag_name -eq 'nightly'}  | Select-Object -ExpandProperty assets | Sort-Object -Property "updated_at" -Descending 
        $GithubDetails_ForDownload = $GithubDetails_Sorted  | Where-Object { $_.name -match $Name } | Select-Object -First 1
    } 
    else {
        Write-Error "Error with input! Exiting!"
        exit

    }

    $GithubDownloadURL = $GithubDetails_ForDownload[0].browser_download_url 
    Write-InformationMessage -Message ('Downloading Files for URL: '+$GithubDownloadURL)
    # Write-debug "GithubDownload: $GithubDownloadURL LocationforDownload: $LocationforDownload"
    if ((Get-DownloadFile -DownloadURL $GithubDownloadURL -OutputLocation $LocationforDownload -NumberofAttempts 3) -eq $true){
        Write-InformationMessage -Message 'Download completed'  
    }
    else{
        Write-ErrorMessage -Message "Error downloading $LocationforDownload!"
        return $false
    }       

    return $true   
}

