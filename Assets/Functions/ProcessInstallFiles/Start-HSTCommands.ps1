function Start-HSTCommands {
    param (
        $HSTScript,
        $Section,
        $ActivityDescription,
        $TotalSteps,
        [switch]$ReportActualSteps,
        [switch]$ReportTime,
        [switch]$DebugFlag
    )
    
    If ($DebugFlag){
        $LogNameDateTime = (Get-Date -Format yyyyMMddHHmmss).tostring()
        $DetailedLogLocation = join-pathMulti $Script:Settings.LogFolder "$LogNameDateTime`_HSTAmigaDebugLog.txt" -UseFullPath
    }
    elseif ($Script:Settings.HSTDetailedLogEnabled -eq $true){
        $DetailedLogLocation = $Script:Settings.HSTDetailedLogLocation
    }
     
    $loggingEnabled = ($Script:Settings.HSTDetailedLogEnabled -eq $true) -or ($DebugFlag)

    if (-not ($TotalSteps) -and ($Section)){
        
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
    
    $startInfo.FileName = $([System.IO.Path]::GetFullPath("$($Script:ExternalProgramSettings.HSTImagerPath)"))
    $startInfo.Arguments = $Arguments
    $startInfo.RedirectStandardOutput = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    
    if ($loggingEnabled){
        $streamWriter = [System.IO.StreamWriter]::new($DetailedLogLocation, $true)  # Open StreamWriter to file
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
        if ($loggingEnabled){
            $streamWriter.WriteLine($line) 
        }
        if ($line -match '\[.*?ERR\]') {
            Write-ErrorMessage -Message "Error running HST Imager! Error was: $line"

            Write-Progress -Activity $ActivityDescription -Completed
            if ($loggingEnabled){
                $streamWriter.Close()   # Close the StreamWriter so file is saved properly
            }
            Write-HSTCommandstoLog
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
    
    if ($loggingEnabled){
        $line = "Log entries for: HST Imager ran with the following arguments [$Arguments] - FINISH"
        $streamWriter.WriteLine($line)
        $streamWriter.WriteLine()
        $streamWriter.Close()   # Close the StreamWriter so file is saved properly
    }
    
    Write-Progress -Activity $ActivityDescription -Completed
}
