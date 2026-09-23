function Get-AmigaFileWeb {
    Param (
        [string]$URL,         
        [string]$BackupURL = $null,
        [string]$LocationforDL,
        [array]$AminetMirrors,
        [int]$NumberofAttempts = 1,
        [bool]$RunParallel = $false,
        $ParallelRunLogFolder
    )  

    # $URL = "http://aminet.net/util/shell/LList.lha"
    # $BackupURL = $null
    # $LocationforDL = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\WebPackagesDownload\Llist.lha"
    # $AminetMirrors = Get-InputFileCSV -CSV 'AminetMirrors'
    # $NumberofAttempts = 1
    # $RunParallel = $true
    # $ParallelRunLogFolder = join-pathMulti $Script:Settings.TempFolder "ParallelRunDebugLogs" -UseFullPath

    If ($RunParallel) {
        $ThreadID = [System.Threading.Thread]::CurrentThread.ManagedThreadId
        $DebugLog = join-path $ParallelRunLogFolder "Thread$($ThreadID)_Download_Hang_Debug.log"
        $StartTime = [datetime]::Now
        "$($StartTime.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Starting Download" | Out-File $DebugLog -Append
    }
    $uri = [System.Uri]$URL
    
    If ($uri.Host -eq "aminet.net") {
        $AminetDL = $true
        $AminetMirrors = $AminetMirrors | Sort-Object { $_.FirstServer -eq $true}, { Get-Random } -Descending
        $URLstoTry = foreach ($mirror in $AminetMirrors) {
            [PSCustomObject]@{
                Type             = "Aminet Mirror"
                URL              = "$($mirror.Type)://$($mirror.MirrorURL)$($uri.PathAndQuery)"
                NumberofAttempts = $NumberofAttempts
            }
        }            
    }
    else {
        $AminetDL = $false
        $URLstoTry = @(
            [PSCustomObject]@{ Type = 'Main Server'; URL = $URL; NumberofAttempts = $NumberofAttempts }
        )
        if ($BackupURL) {
            $URLstoTry += [PSCustomObject]@{ Type = 'Backup Server'; URL = $BackupURL; NumberofAttempts = $NumberofAttempts }
        }
    }
    
    $clientTurran = [System.Net.Http.HttpClient]::new()
    $clientTurran.DefaultRequestHeaders.UserAgent.ParseAdd("AmigaHttpClient")    
    $client = [System.Net.Http.HttpClient]::new()
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("PowerShellHttpClient")
    $success = $false
      
    if ($RunParallel) {
        "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Download of file: `"$(Split-Path $LocationforDL -Leaf)`"" | Out-File $DebugLog -Append
    }
    else {
        Write-InformationMessage -Message "Download of file: `"$(Split-Path $LocationforDL -Leaf)`"" -NewLineBefore 
    }

    :MirrorLoop
    foreach ($item in $URLstoTry) {
        if ($RunParallel) {
            "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Trying Download: $($item.URL)" | Out-File $DebugLog -Append
        }
        else {
            Write-InformationMessage -Message "Trying to download from: $($item.URL)"
        }
        $URLHost = ([System.Uri]$item.URL).Host        
        if (($URLHost -eq 'ftp2.grandis.nu') -or ($URLHost -eq 'ftp.grandis.nu')) { $UserAgenttoUse = "Amiga" } else { $UserAgenttoUse = "PowerShell" }
        for ($attempt = 1; $attempt -le $item.NumberofAttempts; $attempt++) {
            $response = $null
            $stream = $null
            $fileStream = $null
            try {
                if ($AminetDL -ne $true -and $attempt -gt 1) {
                    $TimeforRetry = (5 * ($attempt - 1))
                    if (-not ($RunParallel)) {
                        Write-InformationMessage -Message "Waiting $TimeforRetry seconds before trying again"
                    }                                                
                    Start-Sleep -Seconds $TimeforRetry
                    $RetryAttempt = $attempt - 1
                    if ($RunParallel) {
                        "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Trying Download again. Retry Attempt # $RetryAttempt : $($item.URL)" | Out-File $DebugLog -Append
                    }
                    else {
                        Write-InformationMessage -Message "Trying Download again. Retry Attempt # $RetryAttempt" 
                    }                    
                }
                $TimeoutSeconds = 5
                $TimeSpan = [System.TimeSpan]::FromSeconds($TimeoutSeconds)                
                $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new($TimeSpan)

                If ($RunParallel){
                    "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Attempting GetAsync: $($item.URL)" | Out-File $DebugLog -Append
                }

                if ($UserAgenttoUse -eq "PowerShell") {
                    $response = $client.GetAsync($item.URL, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead,$CancellationTokenSource.token).Result
                }
                elseif ($UserAgenttoUse -eq "Amiga") {
                    $response = $clientTurran.GetAsync($item.URL, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead,$CancellationTokenSource.token).Result
                }
                else {
                    if (-not ($RunParallel)) {
                        Write-ErrorMessage -Message "Incorrect UserAgent!"
                    }
                    exit
                }

                If ($RunParallel){
                    "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);GetAsync successful. Checking status..." | Out-File $DebugLog -Append
                }
                
                if ($response.IsSuccessStatusCode) {
                    $FileLength = $response.Content.Headers.ContentLength
                    $stream = $response.Content.ReadAsStreamAsync().Result
                    $fileStream = [System.IO.File]::OpenWrite($LocationforDL)
                    $buffer = New-Object byte[] 65536  # 64 KB
                    $read = 0
                    $totalRead = 0
                    $percentComplete = 0
                
                    If ($RunParallel){
                        "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Stream open. Starting while loop..." | Out-File $DebugLog -Append
                    }
                
                    if ($stream.CanTimeout) {
                        $stream.ReadTimeout = $TimeoutSeconds * 1000
                    }
                
                    while ($true) {
                        $task = $stream.ReadAsync($buffer, 0, $buffer.Length, $CancellationTokenSource.Token)
                        
                        if (-not $task.Wait($TimeSpan)) {
                            throw "Download stream timed out after $TimeoutSeconds seconds of inactivity."
                        }
                
                        $read = $task.Result
                
                        if ($read -le 0) {
                            break
                        }
                
                        $fileStream.Write($buffer, 0, $read)
                        $CancellationTokenSource.CancelAfter($TimeSpan)
                
                        if (-not ($RunParallel)) {
                            $totalRead += $read
                            if ($FileLength) {
                                $newPercent = [math]::Floor(($totalRead / $FileLength) * 100)
                                if ($newPercent -ne $percentComplete) {
                                    $percentComplete = $newPercent
                                    Write-Progress -Activity "Downloading" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
                                }
                            }
                        }
                    }
                
                    If ($RunParallel){
                        "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);While loop finished cleanly." | Out-File $DebugLog -Append
                    }
                    
                    # Flushes and unlocks the destination file prior to file size checks
                    $fileStream.Dispose()
                    $fileStream = $null
                    $stream.Dispose()
                    $stream = $null
                
                    # File Existence and Size Verification
                    if ((Test-Path -Path $LocationforDL) -and ((Get-Item -Path $LocationforDL).Length -gt 0)) {
                        $downloadedSize = (Get-Item -Path $LocationforDL).Length
                        
                        # Validate against Content-Length header if available
                        if ($null -ne $FileLength -and $downloadedSize -ne $FileLength) {
                            if ($RunParallel) {
                                "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);File size mismatch. Expected $FileLength bytes, got $downloadedSize bytes." | Out-File $DebugLog -Append
                            }
                            else {
                                Write-InformationMessage -Message "File size mismatch. Expected $FileLength bytes, got $downloadedSize bytes."
                            }                            
                            Remove-Item -Path $LocationforDL -Force -ErrorAction SilentlyContinue
                        } else {
                            $success = $true
                            break MirrorLoop
                        }
                    } 
                    else {
                        if ($RunParallel) {
                            "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);File missing or zero bytes after download." | Out-File $DebugLog -Append                        
                        }
                        else {
                            Write-InformationMessage -Message "File missing or zero bytes after download."
                        }                    
                        Remove-Item -Path $LocationforDL -Force -ErrorAction SilentlyContinue
                    }
                }
                
                else {
                    if ($RunParallel) {
                        "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);HTTP request failed. Status Code: $($response.StatusCode) Reason Phrase: $($response.ReasonPhrase)" | Out-File $DebugLog -Append   
                    }
                    else {
                        Write-InformationMessage -Message "HTTP request failed. Status Code: $($response.StatusCode) Reason Phrase: $($response.ReasonPhrase)"                
                    }                                                                                                                                           
                }
            }
            catch {
                if (-not ($RunParallel)) {
                    Write-InformationMessage -Message "Error in attempt $attempt"
                }                
            }
            finally {                                
                if ($null -ne $response) { $response.Dispose() }
                if ($null -ne $stream) { $stream.Dispose() }
                if ($null -ne $fileStream) { $fileStream.Dispose() }
                if ($null -ne $CancellationTokenSource) { $CancellationTokenSource.Dispose() }
            }                    
        }     
    }
    
    if (-not $RunParallel) {
        Write-Progress -Activity "Downloading" -Completed
    }

    if (-not ($RunParallel)) {
        if ($success) {
            Write-InformationMessage -Message "Download completed"
        }
        else {
            Write-ErrorMessage -Message "All download attempts failed for `"$(Split-Path $LocationforDL -Leaf)`"!"
        }
    }

    If ($RunParallel){
        $EndTime = [datetime]::Now
        $ElapsedTime = ($EndTime - $StartTime)
        "$($EndTime.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Elapsed Time: $($ElapsedTime.TotalSeconds)  Finished Download" | Out-File $DebugLog -Append
    }
        
    return $success
}

# function Get-AmigaFileWeb {
#     Param (
#         [string]$URL,         
#         [string]$BackupURL = $null,
#         [string]$LocationforDL,
#         [array]$AminetMirrors,
#         [int]$NumberofAttempts = 1,
#         [bool]$RunParallel = $false,
#         $ParallelRunLogFolder
#     )  

#     # $URL = "https://aminet.net/util/shell/LList.lha"
#     # $BackupURL = $null
#     # $LocationforDL = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\WebPackagesDownload\Llist.lha"
#     # $AminetMirrors = Get-InputFileCSV -CSV 'AminetMirrors'
#     # $NumberofAttempts = 1
#     # $RunParallel = $true
#     # $ParallelRunLogFolder = join-pathMulti $Script:Settings.TempFolder "ParallelRunDebugLogs" -UseFullPath
    
#     $uri = [System.Uri]$URL

#     If ($RunParallel) {
#         $ThreadID = [System.Threading.Thread]::CurrentThread.ManagedThreadId
#         $DebugLog = join-path $ParallelRunLogFolder "Thread$($ThreadID)_Download_Hang_Debug.log"
#         $StartTime = [datetime]::Now
#         "$($StartTime.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Starting Download" | Out-File $DebugLog -Append
#     }

    
#     If ($uri.Host -eq "aminet.net") {
#         $AminetDL = $true
#         $AminetMirrors = $AminetMirrors | Sort-Object { $_.FirstServer -eq $true}, { Get-Random } -Descending
#         $URLstoTry = foreach ($mirror in $AminetMirrors) {
#             [PSCustomObject]@{
#                 Type             = "Aminet Mirror"
#                 URL              = "$($mirror.Type)://$($mirror.MirrorURL)$($uri.PathAndQuery)"
#                 NumberofAttempts = $NumberofAttempts
#             }
#         }            
#     }
#     else {
#         $AminetDL = $false
#         $URLstoTry = @(
#             [PSCustomObject]@{ Type = 'Main Server'; URL = $URL; NumberofAttempts = $NumberofAttempts }
#         )
#         if ($BackupURL) {
#             $URLstoTry += [PSCustomObject]@{ Type = 'Backup Server'; URL = $BackupURL; NumberofAttempts = $NumberofAttempts }
#         }
#     }
    
#     $clientTurran = [System.Net.Http.HttpClient]::new()
#     $clientTurran.DefaultRequestHeaders.UserAgent.ParseAdd("AmigaHttpClient")    
#     $client = [System.Net.Http.HttpClient]::new()
#     $client.DefaultRequestHeaders.UserAgent.ParseAdd("PowerShellHttpClient")
#     $success = $false
    
#     if (-not ($RunParallel)) {
#         Write-InformationMessage -Message "Download of file: `"$(Split-Path $LocationforDL -Leaf)`"" -NewLineBefore 
#     }
#     else {
#         "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Download of file: `"$(Split-Path $LocationforDL -Leaf)`"" | Out-File $DebugLog
#     }

#     :DownloadLoop
#     foreach ($item in $URLstoTry) {
#         $URLHost = ([System.Uri]$item.URL).Host
#         if (($URLHost -eq 'ftp2.grandis.nu') -or ($URLHost -eq 'ftp.grandis.nu')){
        
#             $UserAgenttoUse = "Amiga"
#         }
#         else {
#             $UserAgenttoUse = "PowerShell"
#         }
#         If ($RunParallel){
#             "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Trying Download: $($item.URL)" | Out-File $DebugLog -Append
#         }
#         else {
#             Write-InformationMessage -Message "Trying to download from: $($item.URL)"
#         }
#         for ($attempt = 1; $attempt -le $item.NumberofAttempts; $attempt++) {
#             $response = $null
#             $stream = $null
#             $fileStream = $null
#             if ($AminetDL -ne $true -and $attempt -gt 1) {
#                 $TimeforRetry = (5 * ($attempt - 1))
#                 if (-not ($RunParallel)) {
#                     Write-InformationMessage -Message "Waiting $TimeforRetry seconds before trying again"
#                 }                                                
#                 Start-Sleep -Seconds $TimeforRetry
#                 if (-not ($RunParallel)) {
#                     $RetryAttempt = $attempt - 1
#                     Write-InformationMessage -Message "Trying Download again. Retry Attempt # $RetryAttempt" 
#                 }
#                 else {
#                     "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Trying Download again. Retry Attempt # $RetryAttempt : $($item.URL)" | Out-File $DebugLog -Append
#                 }                    
#             }
            
#             $TimeoutSeconds = 5
#             $TimeSpan = [System.TimeSpan]::FromSeconds($TimeoutSeconds)                
#             $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new($TimeSpan)
            
#             If ($RunParallel){
#                 "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Attempting GetAsync: $($item.URL)" | Out-File $DebugLog -Append
#             }
#             if ($UserAgenttoUse -eq "PowerShell") {
#                 $response = $client.GetAsync($item.URL, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead,$CancellationTokenSource.token).Result
#             }
#             elseif ($UserAgenttoUse -eq "Amiga") {
#                 $response = $clientTurran.GetAsync($item.URL, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead,$CancellationTokenSource.token).Result
#             }
#             else {
#                 if (-not ($RunParallel)) {
#                     Write-ErrorMessage -Message "Incorrect UserAgent!"
#                 }
#                 exit
#             }

#             if ($response.IsSuccessStatusCode) {
#                 If ($RunParallel){
#                     "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);GetAsync successful. Checking status..." | Out-File $DebugLog -Append
#                 }
#                 $FileLength = $response.Content.Headers.ContentLength
#                 $stream = $response.Content.ReadAsStreamAsync().Result
#                 $fileStream = [System.IO.File]::OpenWrite($LocationforDL)
#                 $buffer = New-Object byte[] 65536  # 64 KB
#                 $read = 0
#                 $totalRead = 0
#                 $percentComplete = 0
            
#                 If ($RunParallel){
#                     "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Stream open. Starting while loop..." | Out-File $DebugLog -Append
#                 }

#                 if ($stream.CanTimeout) {
#                     $stream.ReadTimeout = $TimeoutSeconds * 1000
#                 }
#                 while ($true) {
#                     $task = $stream.ReadAsync($buffer, 0, $buffer.Length, $CancellationTokenSource.Token)
                    
#                     if (-not $task.Wait($TimeSpan)) {
#                         throw "Download stream timed out after $TimeoutSeconds seconds of inactivity."
#                     }
            
#                     $read = $task.Result
            
#                     if ($read -le 0) {
#                         break
#                     }
            
#                     $fileStream.Write($buffer, 0, $read)
#                     $CancellationTokenSource.CancelAfter($TimeSpan)
            
#                     if (-not ($RunParallel)) {
#                         $totalRead += $read
#                         if ($FileLength) {
#                             $newPercent = [math]::Floor(($totalRead / $FileLength) * 100)
#                             if ($newPercent -ne $percentComplete) {
#                                 $percentComplete = $newPercent
#                                 Write-Progress -Activity "Downloading" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
#                             }
#                         }
#                     }
#                 }
                
#                 If ($RunParallel){
#                     "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);While loop finished cleanly." | Out-File $DebugLog -Append
#                 }
                
#                 # Flushes and unlocks the destination file prior to file size checks
#                 $fileStream.Dispose()
#                 $fileStream = $null
#                 $stream.Dispose()
#                 $stream = $null        
#                 $CancellationTokenSource.Dispose()
#                 $response.Dispose()
              
#                 if ((Test-Path -Path $LocationforDL) -and ((Get-Item -Path $LocationforDL).Length -gt 0)) {
#                     $downloadedSize = (Get-Item -Path $LocationforDL).Length
#                     # Validate against Content-Length header if available
#                     if ($null -ne $FileLength -and $downloadedSize -ne $FileLength) {
#                         if ($RunParallel) {
#                             "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);File size mismatch. Expected $FileLength bytes, got $downloadedSize bytes." | Out-File $DebugLog -Append
#                         }
#                         else {
#                             Write-InformationMessage -Message "File size mismatch. Expected $FileLength bytes, got $downloadedSize bytes."
#                         }
#                         Remove-Item -Path $LocationforDL -Force -ErrorAction SilentlyContinue
#                     } else {
#                         $success = $true
#                         break DownloadLoop
#                     }
#                 } 
#                 else {
#                     if ($RunParallel) {
#                         "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);File missing or zero bytes after download." | Out-File $DebugLog -Append                        
#                     }
#                     else {
#                         Write-InformationMessage -Message "File missing or zero bytes after download."
#                     }
#                     Remove-Item -Path $LocationforDL -Force -ErrorAction SilentlyContinue
#                 }                        
                
#             }
#         }
#     }
    
#     If ($RunParallel){
#         $EndTime = [datetime]::Now
#         $ElapsedTime = ($EndTime - $StartTime)
#     }    

#     If ($success -eq $true){
#         if ($RunParallel) {
#             "$($EndTime.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Elapsed Time: $($ElapsedTime.TotalSeconds)  Finished Download - Success" | Out-File $DebugLog -Append
#         }
#         else {
#             Write-InformationMessage -Message "Download completed"
#             Write-Progress -Activity "Downloading" -Completed
#         }
#     }
#     else {
#         if ($RunParallel) {
#             "$($EndTime.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Elapsed Time: $($ElapsedTime.TotalSeconds)  Finished Download - Fail" | Out-File $DebugLog -Append            
#         }
#         else {
#             Write-ErrorMessage -Message "All download attempts failed for `"$(Split-Path $LocationforDL -Leaf)`"!"
#         }
#     }
    
#     return $success         
    
# }

# function Get-AmigaFileWeb {
#     Param (
#         [string]$URL,         
#         [string]$BackupURL = $null,
#         [string]$LocationforDL,
#         [array]$AminetMirrors,
#         [int]$NumberofAttempts = 1,
#         [bool]$RunParallel = $false,
#         $ParallelRunLogFolder
#     )  

#     # $URL = "http://aminet.net/util/shell/LList.lha"
#     # $BackupURL = $null
#     # $LocationforDL = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\WebPackagesDownload\Llist.lha"
#     # $AminetMirrors = Get-InputFileCSV -CSV 'AminetMirrors'
#     # $NumberofAttempts = 1
#     # $RunParallel = $true
#     # $ParallelRunLogFolder = join-pathMulti $Script:Settings.TempFolder "ParallelRunDebugLogs" -UseFullPath

#     If ($RunParallel) {
#         $ThreadID = [System.Threading.Thread]::CurrentThread.ManagedThreadId
#         $DebugLog = join-path $ParallelRunLogFolder "Thread$($ThreadID)_Download_Hang_Debug.log"
#         $StartTime = [datetime]::Now
#         "$($StartTime.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Starting Download" | Out-File $DebugLog -Append
#     }
   
#     $uri = [System.Uri]$URL
    
#     if (($Url -like "http://*aminet.net*") -or ($Url -like "https://*aminet.net*")) {
#         $AminetDL = $true
#         $AminetMirrors = $AminetMirrors | Sort-Object { $_.FirstServer -eq $true}, { Get-Random } -Descending
#         $URLstoTry = foreach ($mirror in $AminetMirrors) {
#             [PSCustomObject]@{
#                 Type             = "Aminet Mirror"
#                 URL              = "$($mirror.Type)://$($mirror.MirrorURL)$($uri.PathAndQuery)"
#                 NumberofAttempts = $NumberofAttempts
#             }
#         }            
#     }
#     else {
#         $URLstoTry = @(
#             [PSCustomObject]@{ Type = 'Main Server'; URL = $URL; NumberofAttempts = $NumberofAttempts }
#         )
#         if ($BackupURL) {
#             $URLstoTry += [PSCustomObject]@{ Type = 'Backup Server'; URL = $BackupURL; NumberofAttempts = $NumberofAttempts }
#         }
#     }
   
#     $clientTurran = [System.Net.Http.HttpClient]::new()
#     $clientTurran.DefaultRequestHeaders.UserAgent.ParseAdd("AmigaHttpClient")    
#     $client = [System.Net.Http.HttpClient]::new()
#     $client.DefaultRequestHeaders.UserAgent.ParseAdd("PowerShellHttpClient")
#     $success = $false
    
#     if (-not ($RunParallel)) {
#         Write-InformationMessage -Message "Download of file: `"$(Split-Path $LocationforDL -Leaf)`"" -NewLineBefore 
#     }

#     :MirrorLoop
#     foreach ($item in $URLstoTry) {
#         if (-not ($RunParallel)) {
#             Write-InformationMessage -Message "Trying to download from: $($item.URL)"
#         }
#         else {
#             "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Trying Download: $($item.URL)" | Out-File $DebugLog -Append
#         }

#         if (($uri.Host -eq 'ftp2.grandis.nu') -or ($uri.Host -eq 'ftp.grandis.nu')){
#             $UserAgenttoUse = "Amiga"
#         }
#         else {
#             $UserAgenttoUse = "PowerShell"
#         }

#         for ($attempt = 1; $attempt -le $item.NumberofAttempts; $attempt++) {
#             $response = $null
#             $stream = $null
#             $fileStream = $null
#             try {
#                 if ($AminetDL -ne $true -and $attempt -gt 1) {
#                     $TimeforRetry = (5 * ($attempt - 1))
#                     if (-not ($RunParallel)) {
#                         Write-InformationMessage -Message "Waiting $TimeforRetry seconds before trying again"
#                     }                                                
#                     Start-Sleep -Seconds $TimeforRetry
#                     if (-not ($RunParallel)) {
#                         $RetryAttempt = $attempt - 1
#                         Write-InformationMessage -Message "Trying Download again. Retry Attempt # $RetryAttempt" 
#                     }
#                     else {
#                         "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Trying Download again. Retry Attempt # $RetryAttempt : $($item.URL)" | Out-File $DebugLog -Append
#                     }                    
#                 }
#                 $TimeoutSeconds = 5
#                 $TimeSpan = [System.TimeSpan]::FromSeconds($TimeoutSeconds)                
#                 $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new($TimeSpan)

#                 If ($RunParallel){
#                     "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Attempting GetAsync: $($item.URL)" | Out-File $DebugLog -Append
#                 }

#                 if ($UserAgenttoUse -eq "PowerShell") {
#                     $response = $client.GetAsync($item.URL, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead,$CancellationTokenSource.token).Result
#                 }
#                 elseif ($UserAgenttoUse -eq "Amiga") {
#                     $response = $clientTurran.GetAsync($item.URL, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead,$CancellationTokenSource.token).Result
#                 }
#                 else {
#                     if (-not ($RunParallel)) {
#                         Write-ErrorMessage -Message "Incorrect UserAgent!"
#                     }
#                     exit
#                 }

#                 If ($RunParallel){
#                     "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);GetAsync successful. Checking status..." | Out-File $DebugLog -Append
#                 }
                
#                 if ($response.IsSuccessStatusCode) {
#                     $FileLength = $response.Content.Headers.ContentLength
#                     $stream = $response.Content.ReadAsStreamAsync().Result
#                     $fileStream = [System.IO.File]::OpenWrite($LocationforDL)
#                     $buffer = New-Object byte[] 65536  # 64 KB
#                     $read = 0
#                     $totalRead = 0
#                     $percentComplete = 0
                
#                     If ($RunParallel){
#                         "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Stream open. Starting while loop..." | Out-File $DebugLog -Append
#                     }
                
#                     if ($stream.CanTimeout) {
#                         $stream.ReadTimeout = $TimeoutSeconds * 1000
#                     }
                
#                     while ($true) {
#                         $task = $stream.ReadAsync($buffer, 0, $buffer.Length, $CancellationTokenSource.Token)
                        
#                         if (-not $task.Wait($TimeSpan)) {
#                             throw "Download stream timed out after $TimeoutSeconds seconds of inactivity."
#                         }
                
#                         $read = $task.Result
                
#                         if ($read -le 0) {
#                             break
#                         }
                
#                         $fileStream.Write($buffer, 0, $read)
#                         $CancellationTokenSource.CancelAfter($TimeSpan)
                
#                         if (-not ($RunParallel)) {
#                             $totalRead += $read
#                             if ($FileLength) {
#                                 $newPercent = [math]::Floor(($totalRead / $FileLength) * 100)
#                                 if ($newPercent -ne $percentComplete) {
#                                     $percentComplete = $newPercent
#                                     Write-Progress -Activity "Downloading" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
#                                 }
#                             }
#                         }
#                     }
                
#                     If ($RunParallel){
#                         "$([datetime]::Now.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);While loop finished cleanly." | Out-File $DebugLog -Append
#                     }
                    
#                     # Flushes and unlocks the destination file prior to file size checks
#                     $fileStream.Dispose()
#                     $fileStream = $null
#                     $stream.Dispose()
#                     $stream = $null
                
#                     # File Existence and Size Verification
#                     if ((Test-Path -Path $LocationforDL) -and ((Get-Item -Path $LocationforDL).Length -gt 0)) {
#                         $downloadedSize = (Get-Item -Path $LocationforDL).Length
                        
#                         # Validate against Content-Length header if available
#                         if ($null -ne $FileLength -and $downloadedSize -ne $FileLength) {
#                             if (-not $RunParallel) {
#                                 Write-InformationMessage -Message "File size mismatch. Expected $FileLength bytes, got $downloadedSize bytes."
#                             }
#                             Remove-Item -Path $LocationforDL -Force -ErrorAction SilentlyContinue
#                         } else {
#                             $success = $true
#                             break MirrorLoop
#                         }
#                     } else {
#                         if (-not $RunParallel) {
#                             Write-InformationMessage -Message "File missing or zero bytes after download."
#                         }
#                         Remove-Item -Path $LocationforDL -Force -ErrorAction SilentlyContinue
#                     }
#                 }
                
#                 else {
#                     if (-not ($RunParallel)) {
#                         Write-InformationMessage -Message "HTTP request failed. Status Code: $($response.StatusCode) Reason Phrase: $($response.ReasonPhrase)"                
#                     }                                                                                                                                           
#                 }
#             }
#             catch {
#                 if (-not ($RunParallel)) {
#                     Write-InformationMessage -Message "Error in attempt $attempt"
#                 }                
#             }
#             finally {                                
#                 if ($null -ne $response) { $response.Dispose() }
#                 if ($null -ne $stream) { $stream.Dispose() }
#                 if ($null -ne $fileStream) { $fileStream.Dispose() }
#                 if ($null -ne $CancellationTokenSource) { $CancellationTokenSource.Dispose() }
#             }                    
#         }     
#     }
    
#     if (-not $RunParallel) {
#         Write-Progress -Activity "Downloading" -Completed
#     }

#     if (-not ($RunParallel)) {
#         if ($success) {
#             Write-InformationMessage -Message "Download completed"
#         }
#         else {
#             Write-ErrorMessage -Message "All download attempts failed for `"$(Split-Path $LocationforDL -Leaf)`"!"
#         }
#     }

#     If ($RunParallel){
#         $EndTime = [datetime]::Now
#         $ElapsedTime = ($EndTime - $StartTime)
#         "$($EndTime.ToString('HH:mm:ss:ms'));Thread-$([System.Threading.Thread]::CurrentThread.ManagedThreadId);Elapsed Time: $($ElapsedTime.TotalSeconds)  Finished Download" | Out-File $DebugLog -Append
#     }
        
#     return $success
# }
