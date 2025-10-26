function Start-HSTCommands {
    param (
        $HSTScript,
        $Section,
        $ActivityDescription,
        $TotalSteps,
        [switch]$ReportActualSteps,
        [switch]$ReportTime
    )
    
    # $HSTScript = $Script:GUICurrentStatus.HSTCommandstoProcess.ExtractOSFiles
    # $Section = "ExtractOSFiles"
    # $ActivityDescription = "Running HST Imager to extract OS files"
    # $ReportActualSteps = $true
    # $ReportTime = $true
    # $Section = "DiskStructures;WriteFilestoDisk" 
    # $Section = "DiskStructures"
    
# [System.IO.File]::Open($Script:Settings.HSTDetailedLogLocation, 'Open', 'Read', 'ReadWrite'))


    if (-not ($TotalSteps)){
        
        $TotalStepstoUse = 0        
        $Section -split (";") | ForEach-Object {
            if (-not ($Script:GUICurrentStatus.ProgressBarMarkers.$_)){
                $StepsinSection = 1                
            }
            else {
                $StepsinSection = $Script:GUICurrentStatus.ProgressBarMarkers.$_
            }
            $TotalStepstoUse += $StepsinSection            
        }        
    }
    else {
        $TotalStepstoUse = $TotalSteps 
    }

    $HSTCommandScriptPath = "$($Script:Settings.TempFolder)\HSTCommandstoRun.txt"
    $Arguments = "script `"$HSTCommandScriptPath`""
    
    if (Test-Path $HSTCommandScriptPath){
        $null = Remove-Item -Path $HSTCommandScriptPath
    }     
        
    $HSTScript.Command | Out-File -FilePath $HSTCommandScriptPath -Force
    
    Write-InformationMessage -Message "Running HST Imager for the following arguments: [$Arguments]"
    
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $Script:ExternalProgramSettings.HSTImagerPath
    $startInfo.Arguments = $Arguments
    $startInfo.RedirectStandardOutput = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    
    if ($Script:Settings.HSTDetailedLogEnabled -eq $true){
        $streamWriter = [System.IO.StreamWriter]::new($Script:Settings.HSTDetailedLogLocation, $true)  # Open StreamWriter to file
        $line = "Log entries for: HST Imager ran with the following arguments [$Arguments] - START"
        $streamWriter.WriteLine($line)
        $streamWriter.WriteLine()
    }
    
    if ($ReportTime -eq $true){
        # Start timer
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    }
    
    $process.Start() | Out-Null
    
    $currentStep = 0
    
    while (($line = $process.StandardOutput.ReadLine()) -ne $null) {
        if ($Script:Settings.HSTDetailedLogEnabled -eq $true){
            $streamWriter.WriteLine($line) 
        }
        if ($line -match '\[.*?ERR\]') {
            Write-ErrorMessage -Message "Error running HST Imager! Error was: $line"
            Write-Progress -Activity $ActivityDescription -Completed
            if ($Script:Settings.HSTDetailedLogEnabled -eq $true){
                $streamWriter.Close()   # Close the StreamWriter so file is saved properly
            }
            exit            
        }
        if ($line -match '\[.*?INF\]') {
            $currentStep ++
            $newpercent =  [math]::Min([math]::Floor(($currentStep / $TotalStepstoUse) * 100), 100)
            if ($newPercent -ne $percentComplete) {
                $percentComplete = $newPercent
                Write-Progress -Activity $ActivityDescription -Status "$percentcomplete% complete" -PercentComplete $percentComplete
            }
        }
    }
    
    if ($ReportActualSteps -eq $true){
        Write-Host "Total Number of steps used for reporting: $TotalStepstouse. Actual steps was: $currentStep. Difference was $($currentStep-$TotalStepstoUse)"
    }
    
    $process.WaitForExit()
    
    if ($ReportTime -eq $true){
        $stopwatch.Stop()  # Stop timer
        $elapsed = $stopwatch.Elapsed
        $formatted = "{0}h {1}m {2}s" -f $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds
        Write-InformationMessage -Message "Total time to run section $Section was: $formatted" 
    }
    
    if ($Script:Settings.HSTDetailedLogEnabled -eq $true){
        $line = "Log entries for: HST Imager ran with the following arguments [$Arguments] - FINISH"
        $streamWriter.WriteLine($line)
        $streamWriter.WriteLine()
        $streamWriter.Close()   # Close the StreamWriter so file is saved properly
    }
    
    Write-Progress -Activity $ActivityDescription -Completed
}
