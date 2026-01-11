function Test-Architecture {
    param (
        $Architecture
    )

    if ($Architecture -match '64[- ]?bits?') {
        if ($Architecture -match 'ARM') {
            $Valuetoreturn = "ARM"
            Write-WarningMessage -Message "You are running ARM! While some users report this work, this is unsupported!"
        }
        else {
            $Valuetoreturn = "64bit"
        }
    }
    else {
        $Valuetoreturn = "Other"
    }
       
    return $Valuetoreturn

}