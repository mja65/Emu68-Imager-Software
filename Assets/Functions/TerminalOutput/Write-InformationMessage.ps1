function Write-InformationMessage {
    param (
        $Message,
        [switch]$NoLog,
        [Switch]$NewLineBefore,
        [Switch]$NewLineAfter,
        $LogLocation
    )

    If ($LogLocation){
        $LogLocationtoUse = $LogLocation
    }
    else {
        $LogLocationtoUse = $Script:Settings.LogLocation
    }
    
    $Message = "`t$Message"
    
    If ($NewLineBefore){
        $Message = "`n$Message"
    }
    if ($NewLineAfter){
        $Message = "$Message`n"
    }
    
    Write-Host $Message -ForegroundColor Yellow
    if (-not $NoLog){
        $Message | Out-File $LogLocationtoUse -Append -Encoding utf8
    }
}