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


        $DiskDetails = @()

        if ($Script:GUIActions.ListofRemovableMedia){
            $Script:GUIActions.ListofRemovableMedia | ForEach-Object {
                $DiskDetails += "DeviceID: [$($_.DeviceID)] Size of Disk(Bytes): [$($_.SizeofDisk)] Disk Name: [$($_.HSTDiskName)]"
            }
        }
        else {
            $DiskDetails += "No Disks available"
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
ScreenMode Type = [$($Script:GUIActions.ScreenModeType)]
ScreenMode to Use Workbench = [$($Script:GUIActions.ScreenModetoUseWB)]
Workbench BackDrop Enabled = [$($Script:GUIActions.WorkbenchBackDropEnabled)]
ScreenMode Workbench Colour Depth = [$($Script:GUIActions.ScreenModeWBColourDepth)]
Unicam Enabled = [$($Script:GUIActions.UnicamEnabled)]
Unicam Start on Boot = [$($Script:GUIActions.UnicamStartonBoot)]
Unicam Scaling Type = [$($Script:GUIActions.UnicamScalingType)]
Unicam B Parameter = [$($Script:GUIActions.UnicamBParameter)]
Unicam C Parameter = [$($Script:GUIActions.UnicamCParameter)]
Unicam Size XPosition = [$($Script:GUIActions.UnicamSizeXPosition)]
Unicam Size YPosition  = [$($Script:GUIActions.UnicamSizeYPosition)]
Unicam Offset XPosition = [$($Script:GUIActions.UnicamOffsetXPosition)]
Unicam Offset YPosition = [$($Script:GUIActions.UnicamOffsetYPosition)]
Install Media Location (blank is default) = [$($Script:GUIActions.InstallMediaLocation)]  
Kickstart ROM Location (blank is default) [$($Script:GUIActions.ROMLocation)]
SSID [$SSIDtoReturn)]
WifiPassword [$WifiPasswordtoReturn)] 

Available Disks for Selection:

$DiskDetails

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