function Start-HSTAmigaCommands {
    param (
        $HSTScript

    )
         
    $TotalSteps = $HSTScript.Count
    $ActivityDescription = "Running HST Amiga"
    
    $HSTAmigaCommandScriptPath = "$($Script:Settings.TempFolder)\HSTAmigaCommandstoRun.txt"
    $Arguments = "script `"$HSTAmigaCommandScriptPath`""
    
    if (Test-Path $HSTAmigaCommandScriptPath){
        $null = Remove-Item -Path $HSTAmigaCommandScriptPath
    }     
        
    $HSTScript | Out-File -FilePath $HSTAmigaCommandScriptPath -Force
    
    Write-InformationMessage -Message "Running HST Amiga"
    
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $([System.IO.Path]::GetFullPath("$($Script:ExternalProgramSettings.HSTAmigaPath)"))
    $startInfo.Arguments = $Arguments
    $startInfo.RedirectStandardOutput = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    
    if ($Script:Settings.HSTDetailedLogEnabled -eq $true){
        $streamWriter = [System.IO.StreamWriter]::new($Script:Settings.HSTDetailedLogLocation, $true)  # Open StreamWriter to file
        $line = "Log entries for: HST Amiga ran with the following arguments [$Arguments] - START"
        $streamWriter.WriteLine($line)
        $streamWriter.WriteLine()
    }
    
    $process.Start() | Out-Null
    
    $currentStep = 0
    
    while (($line = $process.StandardOutput.ReadLine()) -ne $null) {
        if ($Script:Settings.HSTDetailedLogEnabled -eq $true){
            $streamWriter.WriteLine($line) 
        }
        if ($line -match '\[.*?ERR\]') {
            Write-ErrorMessage -Message "Error running HST Amiga! Error was: $line"
            Write-Progress -Activity $ActivityDescription -Completed
            if ($Script:Settings.HSTDetailedLogEnabled -eq $true){
                $streamWriter.Close()   # Close the StreamWriter so file is saved properly
            }
            exit            
        }
        if ($line -match '\[.*?INF\]') {
            $currentStep ++
            $newpercent =  [math]::Min([math]::Floor(($currentStep / $TotalSteps) * 100), 100)
            if ($newPercent -ne $percentComplete) {
                $percentComplete = $newPercent
                Write-Progress -Activity $ActivityDescription -Status "$percentcomplete% complete" -PercentComplete $percentComplete
            }
        }
    }
      
    $process.WaitForExit()
        
    if ($Script:Settings.HSTDetailedLogEnabled -eq $true){
        $line = "Log entries for: HST Amiga ran with the following arguments [$Arguments] - FINISH"
        $streamWriter.WriteLine($line)
        $streamWriter.WriteLine()
        $streamWriter.Close()   # Close the StreamWriter so file is saved properly
    }
    
    Write-Progress -Activity $ActivityDescription -Completed

}
