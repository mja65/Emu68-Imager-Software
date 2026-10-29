function Write-ErrorMessage {
    param (
        $Message,
        [switch]$NoLog
    )
    Write-Host "[ERROR] `t $Message" -ForegroundColor Red
    if (-not $NoLog){
        "[ERROR] `t $Message" | Out-File $Script:Settings.LogLocation -Append -Encoding utf8
    }
}