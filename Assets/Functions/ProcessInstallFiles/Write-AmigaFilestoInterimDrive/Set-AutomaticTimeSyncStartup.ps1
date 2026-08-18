function Set-AutomaticTimeSyncStartup {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserStartupPath,

        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    if (-not (Test-Path -LiteralPath $UserStartupPath -PathType Leaf)) {
        return
    }

    $TimeSyncCommand = 'Run >NIL: RX SYS:PiStorm/Network/SyncTime.rexx'
    $UserStartup = Import-TextFileforAmiga -ImportFile $UserStartupPath -SystemType 'Amiga'
    $RevisedUserStartup = [System.Collections.Generic.List[string]]::new()

    foreach ($Line in $UserStartup) {
        if ($Line.Trim() -eq $TimeSyncCommand) {
            if ($Enabled) {
                $RevisedUserStartup.Add($TimeSyncCommand)
            }
            continue
        }

        if ($Line -match 'Network\.rexx.+ipstack=AmiNetXDuo') {
            $Line = $Line -replace '\s+NoSyncTime\s*$', ''
            if (-not $Enabled) {
                $Line += ' NoSyncTime'
            }
        }

        $RevisedUserStartup.Add($Line)
    }

    Export-TextFileforAmiga -DatatoExport $RevisedUserStartup `
                            -ExportFile $UserStartupPath `
                            -AddLineFeeds 'TRUE'
}
