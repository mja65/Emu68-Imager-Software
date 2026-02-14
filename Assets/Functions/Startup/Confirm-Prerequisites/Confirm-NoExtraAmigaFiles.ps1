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
    \System\C\ListDevices
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
    \System\OneTimeRun\CheckScreenModeandChipset
    \System\OneTimeRunWB\LocaleSettings
    \System\OneTimeRunWB\Cmdline
    \System\PiStorm\DebugTools\CheckHashes
    \System\PiStorm\DebugTools\CheckIconPositions
    \System\PiStorm\Documentation
    \System\PiStorm\Documentation.info
    \System\PiStorm\Emu68-Updater.rexx
    \System\PiStorm\Emu68-Updater.info
    \System\PiStorm\Emu68 Utilities\Emu68Info.r
    \System\PiStorm\Emu68 Utilities\Emu68Info.r.info
    \System\PiStorm\Emu68 Utilities\Emu68Meter
    \System\PiStorm\Emu68 Utilities\Emu68Meter.info
    \System\PiStorm\Emu68 Utilities\Emu68Meter.png
    \System\PiStorm\Install Packages
    \System\PiStorm\Install Packages.info
    \System\PiStorm\Network\Network.rexx
    \System\PiStorm\Network\OfflineScriptMenutools_Roadshow
    \System\PiStorm\Network\OfflineScriptMenutools_Miami
    \System\PiStorm\Network\OnlineGENetScriptMenutools_Roadshow
    \System\PiStorm\Network\OnlineGENetScriptMenutools_Miami
    \System\PiStorm\Network\OnlineWifiScriptMenuTools_Roadshow
    \System\PiStorm\Network\OnlineWifiScriptMenuTools_Miami
    \System\PiStorm\Network\Onlinev2expethScriptMenutools_Roadshow
    \System\PiStorm\Network\Onlinev2expethScriptMenutools_Miami
    \System\PiStorm\Network\_UAEFSDB.___
    \System\PiStorm\Offline_Miami.info
    \System\PiStorm\OnlineGENet_Miami.info
    \System\PiStorm\OnlineWifi_Miami.info
    \System\PiStorm\Offline_Roadshow.info
    \System\PiStorm\OnlineGENet_Roadshow.info
    \System\PiStorm\OnlineWifi_Roadshow.info
    \System\PiStorm\RoadshowParameters
    \System\PiStorm\RoadshowParameters.info
    \System\PiStorm\SMB Config
    \System\PiStorm\SMB Config.info
    \System\PiStorm\TransferKick
    \System\PiStorm\TransferKick.info
    \System\PiStorm\WiFi Config
    \System\PiStorm\WiFi Config.info
    \System\Prefs\Env-Archive\FIRSTTIMEBOOT
    \System\Prefs\Env-Archive\FIRSTTIMEBOOTWB
    \System\Prefs\Env-Archive\REBOOT
    \System\Prefs\Env-Archive\ReqTools.prefs
    \System\Prefs\Env-Archive\Picasso96\DisableAmigaBlitter
    \System\Prefs\Env-Archive\Sys\screenmode.prefs
    \System\Prefs\Env-Archive\Sys\Workbench.prefs
    \System\Prefs\Env-Archive\genet_Miami.prefs
    \System\Prefs\Env-Archive\genet_Roadshow.prefs       
    \System\Programs\DOpus\DirectoryOpus.info.txt
    \System\Programs\DOpus\C\DOpusEdit
    \System\Programs\IBrowse\IBrowse.prefs
    \System\Programs\Miami\Genet.default
    \System\Programs\Miami\Genet.default.info
    \System\Programs\Miami\Uaenet.default
    \System\Programs\Miami\Uaenet.default.info
    \System\Programs\Miami\Wifipi.default
    \System\Programs\Miami\Wifipi.default.info
    \System\S\CheckScreenModeandChipset.rexx
    \System\S\DirectoryOpus.CFG
    \System\S\DST.dat
    \System\S\KickstartRomHashes
    \System\S\ProgressBar.rexx
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
    \System\S\User-Startup_Miami
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