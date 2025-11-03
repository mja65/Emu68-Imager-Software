function Write-WarningMessage {
    param (
        $Message,
        [switch]$NoLog
    )
    Write-Host "[WARNING] `t $Message" -ForegroundColor DarkYellow
    if (-not $NoLog){
        "[WARNING] `t $Message" | Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    }
}