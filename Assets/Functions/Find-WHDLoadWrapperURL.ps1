function Find-WHDLoadWrapperURL {
    param (
        $SearchCriteria,
        $ResultLimit
        )        
        $SiteLink='http://ftp2.grandis.nu'
        $ListofURLs = New-Object System.Collections.Generic.List[System.Object]
        
        $Counter = 0
        $IsSuccess = $null
        
        do {
            try {
                $SearchResults=Invoke-WebRequest "http://ftp2.grandis.nu/turransearch/search.php?_search_=1&search=$SearchCriteria&category_id=Misc&exclude=&limit=$ResultLimit&httplinks=on&username=ftp%2Cany&filesonly=on" -UseBasicParsing 
                                               

                $IsSuccess = $true  
            }
            catch {
                Write-InformationMessage -message 'Download failed! Retrying in 3 seconds'
                Start-Sleep -Seconds 3
                $IsSuccess = $false
            }
            $Counter ++              
        } until (
            $IsSuccess -eq $true -or $Counter -eq 3 
        )

        if ($IsSuccess -eq $false){
            Write-ErrorMessage "Unable to access website!"
            return
        }
        else{
            Write-InformationMessage -Message ('Retrieving link latest version of '+$SearchCriteria)
            foreach ($Item in $SearchResults.Links.OuterHTML){
                if ($item -match $SearchCriteria){
                    $Startpoint=$item.IndexOf('/turran')
                    $Endpoint=$item.IndexOf('">/Misc/')
                    $InvidualURL=$item.Substring($Startpoint,($Endpoint-$Startpoint))
                    $ListofURLs.Add($InvidualURL)    
                }
            }
            $DownloadLink = $SiteLink+($ListofURLs | Sort-Object -Descending | Select-Object -First 1)
            if ($DownloadLink){
                return $DownloadLink
            }
            else {
                Write-ErrorMessage "Unable to find WHDLoadWrapper file to download!"
                return
            }
        }
    }