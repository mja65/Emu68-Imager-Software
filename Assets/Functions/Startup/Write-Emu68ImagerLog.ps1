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
        $LogEntry =     @"

Parameters used: 

Script:HSTDiskName =  [$Script:HSTDiskName]
Script:DiskFriendlyName = [$Script:DiskFriendlyName]
Script:ScreenModetoUse = [$Script:ScreenModetoUse]
Script:ScreenModetoUseFriendlyName = [$Script:ScreenModetoUseFriendlyName]
Script:KickstartVersiontoUse = [$Script:KickstartVersiontoUse]
Script:SizeofFAT32 = [$Script:SizeofFAT32]
Script:SizeofImage = [$Script:SizeofImage]
Script:SizeofDisk = [$Script:SizeofDisk]
Script:SizeofPartition_System = [$Script:SizeofPartition_System]
Script:SizeofPartition_Other = [$Script:SizeofPartition_Other]
Script:ImageOnly = [$Script:ImageOnly]
Script:SetDiskupOnly = [$Script:SetDiskupOnly]
Script:WorkingPath = [$Script:WorkingPath]
Script:WorkingPathDefault = [$Script:WorkingPathDefault]
Script:ROMPath = [$Script:ROMPath]
Script:ADFPath = [$Script:ADFPath]
Script:LocationofImage = [$Script:LocationofImage]
Script:TransferLocation = [$Script:TransferLocation]
Script:WriteMethod = [$Script:WriteMethod]
Script:DeleteAllWorkingPathFiles = [$Script:DeleteAllWorkingPathFiles]

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