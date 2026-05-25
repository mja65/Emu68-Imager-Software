function Get-DownloadFile {
    param (
        $DownloadURL,
        $OutputLocation, #Needs to include filename!
        $NumberofAttempts
    )

#    $NumberofAttempts = 2
#    $DownloadURL = "https://mja65.github.io/Emu68-Imager/InstructionsEmu68ImagerV1.html"
#    $DownloadURL = "http://www.ibrowse-dev.net/resources/IBrowse3.0a-OS31.lha"
#    $OutputLocation = 'E:\PiStorm\Docs\Test.html'

    $uri = [System.Uri]$DownloadURL
    
    $client = [System.Net.Http.HttpClient]::new()
            
    if (($uri.Host -eq 'ftp2.grandis.nu') -or ($uri.Host -eq 'ftp2.grandis.nu')){
        $client.DefaultRequestHeaders.UserAgent.ParseAdd("AmigaHttpClient")    
    }
    else {
        $client.DefaultRequestHeaders.UserAgent.ParseAdd("PowerShellHttpClient")
    }
    
    $attempt = 1
    $success = $false
    
    while (-not $success -and $attempt -le $NumberofAttempts) {
        if ($attempt -gt 1){
            $TimeforRetry = (5 * ($attempt-1))
            Write-InformationMessage -Message "Waiting $TimeforRetry seconds before trying again"
            Start-Sleep -Seconds $TimeforRetry
            Write-InformationMessage -Message ('Trying Download again. Retry Attempt # '+($attempt-1))                            
        }
        $response = $client.GetAsync($DownloadURL , [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
        if (-not $response.IsSuccessStatusCode) {
            Write-InformationMessage -Message "HTTP request failed. Status Code: $($response.StatusCode) Reason Phrase: $($response.ReasonPhrase)"

        }
        else {
            $FileLength = $response.Content.Headers.ContentLength
            $stream = $response.Content.ReadAsStreamAsync().Result
            $fileStream = [System.IO.File]::OpenWrite($OutputLocation)
            $buffer = New-Object byte[] 65536  # 64 KB
            $read = 0
            $totalRead = 0
            $percentComplete = 0
            while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $fileStream.Write($buffer, 0, $read)
                $totalRead += $read
                $newPercent = [math]::Floor(($totalRead/$FileLength)*100)
                if ($newPercent -ne $percentComplete) {
                    $percentComplete = $newPercent
                    Write-Progress -Activity "Downloading" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
                }
            }
            Write-Progress -Activity "Downloading" -Completed -Status "Done"
            $success = $true                            
        }
        
        $attempt++          
        
    }
       
    if ($stream){
        $stream.Dispose() 
        $stream = $null 
    }
    
    if ($fileStream) {
        $fileStream.Dispose()
        $fileStream = $null
    }  
    
    return $success      

}
