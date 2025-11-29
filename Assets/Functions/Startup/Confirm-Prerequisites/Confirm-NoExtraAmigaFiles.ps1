function Confirm-NoExtraAmigaFiles {
    param (
        
    )
    
$ListofFiles = @"
    \EMU68Boot\config.txt
    \EMU68Boot\ps32lite-stealth-firmware.gz
    \LocalAmigaPackages\Roadshow-Demo-1.15.lha
    \System\C\AreWeOnline
    \System\C\AreWePAL
    \System\C\CE
    \System\C\Emu68Info
    \System\C\TomCopy
    \System\C\TomDelete
    \System\C\WaitForTask
    \System\C\WaitUntilConnected
    \System\Devs\Picasso96Settings
    \System\Devs\DOSDrivers\SD0.info.txt
    \System\Devs\DOSDrivers\SD0pi3
    \System\Devs\DOSDrivers\SD0pi4
    \System\Devs\Monitors\Videocore.info.txt
    \System\Devs\NetInterfaces\genet
    \System\Devs\NetInterfaces\wifipi
    \System\Libs\oc666.library
    \System\OneTimeRun\AUXRename
    \System\OneTimeRun\CopyPalNtsc
    \System\OneTimeRun\Ibrowse
    \System\OneTimeRun\Pi4vsPi3_Pistorm
    \System\OneTimeRun\CheckScreenModeandChipset_Pistorm
    \System\OneTimeRunWB\LocaleSettings
    \System\PiStorm\Documentation
    \System\PiStorm\Documentation.info
    \System\PiStorm\Emu68Info.r
    \System\PiStorm\Emu68Info.r.info
    \System\PiStorm\Emu68Meter
    \System\PiStorm\Emu68Meter.info
    \System\PiStorm\Emu68Meter.png
    \System\PiStorm\Install Packages
    \System\PiStorm\Install Packages.info
    \System\PiStorm\Offline.info
    \System\PiStorm\OfflineScriptMenutools
    \System\PiStorm\Online
    \System\PiStorm\OnlineGENet.info
    \System\PiStorm\OnlineGENetScriptMenutools
    \System\PiStorm\OnlineWifi.info
    \System\PiStorm\OnlineWifiScriptMenuTools
    \System\PiStorm\ReadRoadshowParameters.rexx
    \System\PiStorm\RoadshowParameters
    \System\PiStorm\RoadshowParameters.info
    \System\PiStorm\SMB Config
    \System\PiStorm\SMB Config.info
    \System\PiStorm\TransferKick
    \System\PiStorm\TransferKick.info
    \System\PiStorm\WiFi Config
    \System\PiStorm\WiFi Config.info
    \System\PiStorm\Emu68-Updater\Emu68-Updater
    \System\PiStorm\Emu68-Updater\Emu68-Updater.info
    \System\PiStorm\Emu68-Updater\tag.rexx
    \System\PiStorm\Emu68-Updater\Updater
    \System\Prefs\Env-Archive\FIRSTTIMEBOOT
    \System\Prefs\Env-Archive\FIRSTTIMEBOOTWB
    \System\Prefs\Env-Archive\REBOOT
    \System\Prefs\Env-Archive\ReqTools.prefs
    \System\Prefs\Env-Archive\Picasso96\DisableAmigaBlitter
    \System\Prefs\Env-Archive\Sys\screenmode.prefs
    \System\Prefs\Env-Archive\Sys\Workbench.prefs
    \System\Programs\DOpus\DirectoryOpus.info.txt
    \System\Programs\DOpus\C\DOpusEdit
    \System\Programs\IBrowse\IBrowse.prefs
    \System\S\CheckScreenModeandChipset.rexx
    \System\S\DirectoryOpus.CFG
    \System\S\DST.dat
    \System\S\KickstartRomHashes
    \System\S\ProgressBar
    \System\S\Startup-Sequence_Iconlib
    \System\S\Startup-Sequence_OneTimeRun
    \System\S\Startup-Sequence_REXXMAST
    \System\S\Startup-Sequence_UAEGFX
    \System\S\Startup-Sequence_REXXMASTFAILAT10
    \System\S\Startup-Sequence_REXXMASTFAILAT21
    \System\S\User-Startup_AmiSSL
    \System\S\User-Startup_MUI38
    \System\S\User-Startup_Picasso96
    \System\S\User-Startup_Roadshow
    \System\S\_UAEFSDB.___
    \System\Storage\DosDrivers\SMB0
    \System\Storage\DosDrivers\SMB0.info.txt
    \System\Tools\HDToolBoxPi3.info.txt
    \System\Tools\HDToolBoxPi4.info.txt
    \System\WBStartup\Menutools_1
    \System\WBStartup\Menutools_2
    \System\WBStartup\OneTimeRunWB
    \System\WBStartup\OneTimeRunWB.info
"@ -split "`r?`n" | Where-Object { $_ -ne "" } | ForEach-Object { $_.Trim().ToLower() }
    
    # Populated through (Get-ChildItem $Script:Settings.LocationofAmigaFiles -Recurse | Where-Object { $_.PSIsContainer -eq $false }).FullName.Replace([System.IO.Path]::GetFullPath($Script:Settings.LocationofAmigaFiles),"")
    
    $FileLookupTable = @{}
    $ListofFiles | ForEach-Object {
        $FileLookupTable.Add($_, $True)
    }
    
    $BasePath = [System.IO.Path]::GetFullPath($Script:Settings.LocationofAmigaFiles)
    
    Write-InformationMessage "Checking for unrequired AmigaFiles and removing"

    Get-ChildItem $Script:Settings.LocationofAmigaFiles -Recurse -File | ForEach-Object {
        $FilePathtoCheck = $_.FullName
        $RelativePath = $FilePathtoCheck.Replace($BasePath,"")
        if ($FileLookupTable.ContainsKey($RelativePath)){
            #Write-Host "Found: $RelativePath"     
        }
        else {
            Write-InformationMessage "Removing file: $RelativePath"
            $null = remove-item $FilePathtoCheck -Force
        }
    }

}