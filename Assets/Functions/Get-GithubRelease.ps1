function Get-GithubRelease {
    param (
        $GithubRepository,
        $GithubReleaseType,
        $Tag_Name,
        $Name,
        $GithubNameExclude,
        $GithubSortTagPrefix,
        $GithubSortSemanticVersion,
        $MinimumPublishedDate,
        [switch]$SortUpdatedBy,
        [switch]$SortTagName
    )
    
    # Write-host "`$GithubRepository = `"$GithubRepository`""
    # Write-host "`$GithubReleaseType = `"$GithubReleaseType`""
    # Write-host "`$Tag_Name = `"$Tag_Name`"" 
    # Write-host "`$Name = `"$Name`""
    # Write-host "`$GithubNameExclude = `"$GithubNameExclude`"" 
    # Write-host "`$GithubSortTagPrefix = `"$GithubSortTagPrefix`""
    # Write-host "`$GithubSortSemanticVersion = `"$GithubSortSemanticVersion`"" 
    # Write-host "`$SortUpdatedBy = `"$SortUpdatedBy`""
    # Write-host "`$SortTagName = `"$SortTagName`""

    # $GithubRepository = "https://api.github.com/repos/pulchart/fat95/releases"
    # $GithubReleaseType = "Release"
    # $Tag_Name = ""
    # $Name = "fat95*.lha"
    # $GithubNameExclude = ""
    # $GithubSortTagPrefix = "fat95.v"
    # $GithubSortSemanticVersion = ""
    # $SortUpdatedBy = ""
    # $SortTagName = ""
    # $MinimumPublishedDate = "2026-06-01"


    $GithubNameExcludeList = @($GithubNameExclude -split ',')
   
    If ($GithubNameExclude){
        Write-InformationMessage -Message "Retrieving Github information for Repository: $GithubRepository Name: `"$Name`" ExcludedName: `"$GithubNameExclude`" "        
    } 
    else {
        Write-InformationMessage -Message "Retrieving Github information for Repository: $GithubRepository Name: `"$Name`""
    }
    If ($GithubReleaseType -eq "nightly"){
        Write-InformationMessage -Message "Using nightly"        
    }
    elseif ($Tag_Name){
        Write-InformationMessage -Message "Using specified release"        
    }
    else {
        if ($GithubSortSemanticVersion -eq "TRUE"){
            Write-InformationMessage -Message "Using latest release (semantic versioning)"            
        }
        else {
            Write-InformationMessage -Message "Using latest release (standard sort)"
        }
    }

    if ($MinimumPublishedDate){
        Write-InformationMessage -Message "Filtering for releases published after: $MinimumPublishedDate"
    }

    $client = [System.Net.Http.HttpClient]::new()
    if ($Script:GUICurrentStatus.GithubAPIToken){
        $client.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $($Script:GUICurrentStatus.GithubAPIToken))
    } 
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("PowerShellHttpClient")
    $GithubDetails = $null
    
    $Counter = 0
    $IsSuccess = $null
           
    do {
        $GithubDetails = $client.GetStringAsync($GithubRepository)

        If ($GithubDetails.Result){
            $GithubDetails = $GithubDetails.Result | ConvertFrom-Json

            if ($MinimumPublishedDate) {
                $GithubDetails = $GithubDetails.where({ [datetime]$_.published_at -gt [datetime]$MinimumPublishedDate })
            }

            $IsSuccess = $true              
        }
        else {
            if ($GithubDetails.Exception){
                Write-ErrorMessage -Message $GithubDetails.Exception.Message
                Write-ErrorMessage -Message "Error accessing Github! Quitting Program. Error message from Github below:"
                Write-ErrorMessage -Message $($GithubDetails.Exception.ToString())
                $IsSuccess = $false
                return
            }
            else {
                Write-InformationMessage -message "Download failed! Retrying in 3 seconds"
                Start-Sleep -Seconds 3
                $IsSuccess = $false                                
            }
        }
        $Counter ++              
    } until ( $IsSuccess -eq $true -or $Counter -eq 3 )

    if ( -not $GithubDetails){
        Write-ErrorMessage -Message "Error accessing Github! Quitting Program"
        return
    }  

    if ($GithubReleaseType -eq "nightly"){
        Write-InformationMessage "Using Tag: nightly"
        $GithubDetails_Sorted = $GithubDetails | Where-Object { $_.tag_name -eq 'nightly'}  | Select-Object -ExpandProperty assets | Sort-Object -Property "updated_at" -Descending 
        if ($GithubNameExclude){
            $GithubDetails_ForDownload = $GithubDetails_Sorted  | Where-Object { $_.name -match $Name -and $GithubNameExcludeList -notmatch $_.name } | Select-Object -First 1       
        }
        else {
            $GithubDetails_ForDownload = $GithubDetails_Sorted  | Where-Object { $_.name -match $Name } | Select-Object -First 1  
        }
    }
    else{
        if (($GithubReleaseType -eq "Prerelease") -or ($GithubReleaseType -eq "Prerelease-NoArchive")){
            $GithubDetails_Filtered = $GithubDetails | Where-Object  {($_.draft).tostring() -eq 'False' -and ($_.prerelease).tostring() -eq 'True'}
                  
        }
        elseif ($GithubReleaseType -eq "Prerelease-Poseidon") {
            $GithubDetails_Filtered = $GithubDetails | Where-Object  {($_.draft).tostring() -eq 'False' -and ($_.prerelease).tostring() -eq 'True'}
        }
        elseif ($GithubReleaseType -eq "Release" -or $GithubReleaseType -eq "Release-NoArchive"){
            If ($Tag_Name){
                $GithubDetails_Filtered = $GithubDetails | Where-Object { ($_.draft).tostring() -eq 'False' -and ($_.prerelease).tostring() -eq 'False' }
            }
            else {
                $GithubDetails_Filtered = $GithubDetails | Where-Object  {$_.tag_name -notmatch '-rc' -and  $_.tag_name -notmatch '-beta' -and  $_.tag_name -notmatch '-alpha' -and ($_.draft).tostring() -eq 'False' -and ($_.prerelease).tostring() -eq 'False' -and ($_.name).tostring() -notmatch 'Release Candidate'}
            }
        }
        elseif ($GithubReleaseType -eq "Release-Poseidon"){
            If ($Tag_Name){
                $GithubDetails_Filtered = $GithubDetails | Where-Object { ($_.draft).tostring() -eq 'False' -and ($_.prerelease).tostring() -eq 'False' }
            }
            else {
                $GithubDetails_Filtered = $GithubDetails | Where-Object  {($_.draft).tostring() -eq 'False' -and ($_.prerelease).tostring() -eq 'False' }
            }
        }        
        else {
            Write-ErrorMessage -Message "Error with input! Exiting!"
            return                        
        }
        if ($Tag_Name){
            Write-InformationMessage "Using Tag: $Tag_Name"
            if ($GithubNameExclude) {
                $ExcludeRegex = ($GithubNameExcludeList | ForEach-Object { [regex]::Escape($_) }) -join '|'
                $GithubDetails_ForDownload = $GithubDetails_Filtered | Where-Object { $_.tag_name -eq $Tag_Name } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name -and $_.name -notmatch $ExcludeRegex }  
            }
            else {
                $GithubDetails_ForDownload = $GithubDetails_Filtered | Where-Object { $_.tag_name -eq $Tag_Name } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name }    
            }
        }
        else {
            Write-InformationMessage "Finding latest release"
            $GithubDetails_Sorted = $GithubDetails_Filtered | Where-Object { $_.tag_name -ne 'nightly'} | Select-Object *, @{
                Name       = 'clean_tag'
                Expression = { 
                    $NewTag  = $_.tag_name -replace "^$GithubSortTagPrefix", ""
                    if ($GithubSortSemanticVersion -eq "TRUE") { $NewTag -as [version] } else { $NewTag }                    
                }
            } | Sort-Object -Property 'clean_tag' -Descending
            if ($GithubNameExclude){
                $GithubDetails_ForDownload_Initial = $GithubDetails_Sorted | ForEach-Object {
                    $CurrentTag = $_.tag_name
                    $_.assets | ForEach-Object {
                        $_ | Add-Member -NotePropertyMembers @{ tag_name = $CurrentTag } -PassThru -Force
                    }
                } 
                # $GithubDetails_ForDownload = $GithubDetails_ForDownload_Initial | ForEach-Object {
                #     $Match = $Name -like $_.name
                #     Write-host "$Name $($_.name) $Match"
                # }
                $ExcludeRegex = ($GithubNameExcludeList | ForEach-Object { [regex]::Escape($_) }) -join '|'
                $GithubDetails_ForDownload = $GithubDetails_ForDownload_Initial | Where-Object { $_.name -like $Name -and $_.name -notmatch $ExcludeRegex } | Select-Object -First 1
            } 
            else {
                $GithubDetails_ForDownload_Initial = $GithubDetails_Sorted | ForEach-Object {
                    $CurrentTag = $_.tag_name
                    $_.assets | ForEach-Object {
                        $_ | Add-Member -NotePropertyMembers @{ tag_name = $CurrentTag } -PassThru -Force
                    }
                } 
                
                $GithubDetails_ForDownload = $GithubDetails_ForDownload_Initial | Where-Object { $_.name -like $Name -or $_.name -match $Name }| Select-Object -First 1
            }
            Write-InformationMessage "Tag found is: $($GithubDetails_ForDownload.tag_name)"
        }
    }
    
    $GithubDownloadURL = $GithubDetails_ForDownload[0].browser_download_url 
    Write-InformationMessage -Message "Found URL: $GithubDownloadURL"
    return $GithubDownloadURL        
}

