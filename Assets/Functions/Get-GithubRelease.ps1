function Get-GithubRelease {
    param (
        $GithubRepository,
        $GithubReleaseType,
        $Tag_Name,
        $Name,
        $LocationforDownload,
        $FileNameforDownload
    )
  
    #Write-host "GithubRepository: $GithubRepository GithubReleaseType: $GithubReleaseType Tag_Name: $Tag_Name Name:$Name LocationforDownload: $LocationforDownload FileNameforDownload: $FileNameforDownload"

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
    
    # $GithubRepository = "https://api.github.com/repos/henrikstengaard/hst-imager/releases"
    # $GithubReleaseType = 'Release'
    # $Tag_Name = "1.3.484"
    # $Name =  "_console_windows_x64.zip"
    # $FileNameforDownload = "HSTImager.zip"

    #$GithubRepository = "https://api.github.com/repos/rondoval/emu68-genet-driver/releases"
    #$GithubReleaseType = "Release-NoArchive"
    #$Tag_Name = "v1.3"
    #$Name = "genet.device"
    #$FileNameforDownload = "genet.device"


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
      try {
        $GithubDetails = $client.GetStringAsync($GithubRepository).Result | ConvertFrom-Json
        if ($GithubDetails){
            $IsSuccess = $true  
        }
        else {
            Write-InformationMessage -message 'Download failed! Retrying in 3 seconds'
            Start-Sleep -Seconds 3
            $IsSuccess = $false
        }
      }
      catch {
        Write-InformationMessage -Message "Unable to retrieve GitHub release information: $($_.Exception.Message)"
        $IsSuccess = $false
      }
        $Counter ++              
    } until (
        $IsSuccess -eq $true -or $Counter -eq 3 
    )

    if ( -not $GithubDetails){
        Write-ErrorMessage -Message "Error accessing Github release information"
        return $false
    }  

    If (($GithubReleaseType -eq "Release") -or ($GithubReleaseType -eq "Release-NoArchive")){
        if ($Tag_Name){
            $GithubDetails_ForDownload = $GithubDetails | Where-Object { $_.tag_name -eq $Tag_Name } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name }             
        }
        else {
            $GithubDetails_Sorted = $GithubDetails | Where-Object { $_.tag_name -ne 'nightly' -and ($_.draft).tostring() -eq 'False' -and ($_.prerelease).tostring() -eq 'False' -and ($_.name).tostring() -notmatch 'Release Candidate'} | Sort-Object -Property 'published_at' -Descending | Select-Object -ExpandProperty assets
            $NametoCheck = $Name
            $GithubDetails_ForDownload = $GithubDetails_Sorted  | Where-Object { $_.name -match $NametoCheck } | Select-Object -First 1
        }
    }
    elseif ($GithubReleaseType -eq "nightly"){
        $GithubDetails_Sorted = $GithubDetails | Where-Object { $_.tag_name -eq 'nightly'}  | Select-Object -ExpandProperty assets | Sort-Object -Property "updated_at" -Descending 
        $GithubDetails_ForDownload = $GithubDetails_Sorted  | Where-Object { $_.name -match $Name } | Select-Object -First 1
    } 
    else {
        Write-ErrorMessage -Message "Error with input! Exiting!"
        exit

    }

    if (-not $GithubDetails_ForDownload) {
        Write-ErrorMessage -Message "No matching release asset found for $Name"
        return $false
    }

    $GithubDownloadURL = $GithubDetails_ForDownload[0].browser_download_url 
    Write-InformationMessage -Message ('Downloading Files for URL: '+$GithubDownloadURL)
    # Write-debug "GithubDownload: $GithubDownloadURL LocationforDownload: $PathforDownload"
    if ((Get-DownloadFile -DownloadURL $GithubDownloadURL -OutputLocation $PathforDownload -NumberofAttempts 3) -eq $true){
        Write-InformationMessage -Message 'Download completed'  
    }
    else{
        Write-ErrorMessage -Message "Error downloading $PathforDownload!"
        return $false
    }       

    return $true   
}

