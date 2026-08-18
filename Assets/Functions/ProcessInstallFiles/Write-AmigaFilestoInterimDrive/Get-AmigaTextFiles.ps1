function Get-AmigaTextFiles {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    # These are text formats consumed directly by AmigaDOS, ARexx, devices,
    # preferences tools, or Raspberry Pi firmware. Do not replace this with a
    # recursive text/binary guess: many Amiga executables have no extension.
    $RelativePatterns = @(
        'Emu68Boot\*.txt',
        'System\Devs\DOSDrivers\SD0pi3',
        'System\Devs\DOSDrivers\SD0pi4',
        'System\Devs\DOSDrivers\*.info.txt',
        'System\Devs\Monitors\*.info.txt',
        'System\Devs\NetInterfaces\genet',
        'System\Devs\NetInterfaces\wifipi',
        'System\OneTimeRun\*',
        'System\OneTimeRunWB\*',
        'System\PiStorm\DebugTools\CheckHashes',
        'System\PiStorm\DebugTools\CheckIconPositions',
        'System\PiStorm\Documentation',
        'System\PiStorm\Emu68 Utilities\*.r',
        'System\PiStorm\Emu68-Updater.rexx',
        'System\PiStorm\Install Packages',
        'System\PiStorm\Network\*.rexx',
        'System\PiStorm\Network\*ScriptMenu*',
        'System\PiStorm\RoadshowParameters',
        'System\PiStorm\TransferKick',
        'System\Prefs\Env-Archive\FIRSTTIMEBOOT',
        'System\Prefs\Env-Archive\FIRSTTIMEBOOTWB',
        'System\Prefs\Env-Archive\REBOOT',
        'System\Prefs\Env-Archive\genet_*.prefs',
        'System\Prefs\Env-Archive\Sys\wireless.prefs',
        'System\Programs\DOpus\C\DOpusEdit',
        'System\Programs\DOpus\*.info.txt',
        'System\S\*.rexx',
        'System\S\DST.dat',
        'System\S\KickstartRomHashes',
        'System\S\Startup-Sequence_*',
        'System\S\User-Startup*',
        'System\Storage\DosDrivers\SMB0',
        'System\Storage\DosDrivers\*.info.txt',
        'System\Tools\*.info.txt',
        'System\WBStartup\Menutools_1',
        'System\WBStartup\Menutools_2',
        'System\WBStartup\OnetimeRunWB'
    )

    $Files = foreach ($RelativePattern in $RelativePatterns) {
        Get-ChildItem -Path (Join-Path $RootPath $RelativePattern) -File -ErrorAction SilentlyContinue
    }

    return @($Files | Select-Object -ExpandProperty FullName -Unique)
}
