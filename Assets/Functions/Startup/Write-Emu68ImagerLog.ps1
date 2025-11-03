function Write-Emu68ImagerLog {
    param (
        [Switch]$Start,
        [Switch]$Continue
    )

    If ($Start){
        $LogNameDateTime = (Get-Date -Format yyyyMMddHHmmss).tostring()
        $DateandTime = (Get-Date -Format HH:mm:ss)
        $Script:Settings.LogLocation = "$($Script:Settings.LogFolder)\$LogNameDateTime`_Emu68ImagerLog.txt"
        $LogEntry =     @"
Emu68 Imager Log
        
Log created at: $DateandTime
        
Script Version: $($Script:Settings.Version) 
Script Path: $($Script:GUIActions.ScriptPath)
Windows Version: $($Script:Settings.WindowsVersion)
Windows Locale Details: $($Script:Settings.WindowsLocale)
Powershell version used is: $($Script:Settings.PowershellVersion)
Architecture is: $($Script:Settings.Architecture) 
.Net Framework Release installed is: $($Script:Settings.NetFrameworkrelease) 

"@  

        if (-not (Test-Path $Script:Settings.LogFolder)){
            $null = New-Item -Path $Script:Settings.LogFolder -ItemType Directory
        }

        $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
        $streamWriter = New-Object System.IO.StreamWriter($Script:Settings.LogLocation, $false, $utf8NoBOM)

        foreach ($entry in $logEntry) {
            $streamWriter.WriteLine($entry)
        }
        
        $streamWriter.Close()
        #$LogEntry| Out-File -FilePath $Script:Settings.LogLocation

        if ($Script:Settings.HSTDetailedLogEnabled -eq $true){
            $Script:Settings.HSTDetailedLogLocation = "$($Script:Settings.LogFolder)\$LogNameDateTime`_Emu68ImagerHSTLog.txt"
            $LogEntry =     @"
Emu68 Imager Log - HST Detailed Log
        
Log created at: $DateandTime

"@ 
       
            $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
            $streamWriter = New-Object System.IO.StreamWriter($Script:Settings.HSTDetailedLogLocation, $false, $utf8NoBOM)

            foreach ($entry in $logEntry) {
                $streamWriter.WriteLine($entry)
            }
        
            $streamWriter.Close()

            #$LogEntry| Out-File -FilePath $Script:Settings.HSTDetailedLogLocation

        }

    }
    elseif($Continue){ 

        if ($Script:GUIActions.WifiPassword) {
                $WifiPasswordtoReturn = "Populated"
        }
        else {
            $WifiPasswordtoReturn = "Not Populated"
        }
        if ($Script:GUIActions.SSID) {
                $SSIDtoReturn = "Populated"
        }
        else {
            $SSIDtoReturn = "Not Populated"
        }
       
        $LogEntry =     @"

Parameters used: 

Operation Mode = [$($Script:GUICurrentStatus.OperationMode)]
RunMode = [$($Script:GUICurrentStatus.RunMode)]
Default Packages Selected = [$($Script:GUIActions.DefaultPackagesSelected)]
Default IconSet Selected = [$($Script:GUIActions.DefaultIconsetSelected)]
Icon Set Selected = [$($Script:GUIActions.SelectedIconset)]
OS to be installed = [$($Script:GUIActions.KickstartVersiontoUse)]
Script Path = [$($Script:GUIActions.ScriptPath)]
Output Path = [$($Script:GUIActions.OutputPath)]
OutputType = [$($Script:GUIActions.OutputType)]
Install OS Files = [$($Script:GUIActions.InstallOSFiles)]
ScreenMode to Use = [$($Script:GUIActions.ScreenModetoUse)]
Install Media Location (blank is default) = [$($Script:GUIActions.InstallMediaLocation)]  
Kickstart ROM Location (blank is default) [$($Script:GUIActions.ROMLocation)]
SSID [$SSIDtoReturn)]
WifiPassword [$WifiPasswordtoReturn)] 


Activity Commences:

"@
     
        $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
        $streamWriter = New-Object System.IO.StreamWriter($Script:Settings.LogLocation, $true, $utf8NoBOM)

        foreach ($entry in $logEntry) {
            $streamWriter.WriteLine($entry)
        }
        
        $streamWriter.Close()

        #$LogEntry| Out-File -FilePath $Script:Settings.LogLocation -Append -Encoding utf8
    }
}