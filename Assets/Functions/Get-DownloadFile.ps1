function Get-DownloadFile {
    param (
        $DownloadURL,
        $OutputLocation, #Needs to include filename!
        $NumberofAttempts
    )

#    $NumberofAttempts = 2
#    $DownloadURL = "https://mja65.github.io/Emu68-Imager/images/Version2/StartupAdvancedMode.png"
#    $OutputLocation = 'E:\PiStorm\Docs\'
   
    $client = [System.Net.Http.HttpClient]::new()
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("PowerShellHttpClient")
    
    $attempt = 1
    $success = $false
    
    while (-not $success -and $attempt -le $NumberofAttempts) {
      
        try {
            if ($attempt -gt 1){
                Write-InformationMessage -Message ('Trying Download again. Retry Attempt # '+$attempt)
            }
            $response = $client.GetAsync($DownloadURL , [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
            if (-not $response.IsSuccessStatusCode) {
                Write-InformationMessage -Message "HTTP request failed: $($response.StatusCode) $($response.ReasonPhrase)"
                #return $false
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
        }
        catch {
            Write-InformationMessage -message 'Download failed! Retrying in 3 seconds'
            Start-Sleep -Seconds 3
        }
        finally {
            if ($stream){
                $stream.Dispose() 
                $stream = $null 
            }
            if ($fileStream) {
                $fileStream.Dispose()
                $fileStream = $null
            }  
            
        }
        $attempt++          
    }

    return $success      

}
