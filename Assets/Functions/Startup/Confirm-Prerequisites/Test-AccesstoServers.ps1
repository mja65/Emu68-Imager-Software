function Test-AccesstoServers {
    param (
        
    )

    $ServerList = [System.Collections.Generic.List[PSCustomObject]]::New()
     
    $ServerList += [PSCustomObject]@{
       ServerName = "github.com"
        FatalError = 0
    }
    
    $ServerList += [PSCustomObject]@{
        ServerName = "aminet.net"
        FatalError = 0
    }

    $ServerList += [PSCustomObject]@{
        ServerName = "ftp2.grandis.nu"
        FatalError = 0
    }

    $ServerList += [PSCustomObject]@{
        ServerName = "dropbox.com"
        FatalError = 0
    }

    $ServerList += [PSCustomObject]@{
        ServerName = "dopus.free.fr"
        FatalError = 0
    }

    $ServerList += [PSCustomObject]@{
        ServerName = "ibrowse-dev.net"
        FatalError = 0
    }
    
    $ServerList += [PSCustomObject]@{
    ServerName = "mja65.github.io"
    FatalError = 0
}

    $ErrorCount = 0
    $FatalErrorCount = 0

    Write-InformationMessage -Message "Testing accessability of servers. Note, this is an indication only"
    Write-InformationMessage -Message ""

    foreach ($Server in $ServerList) {
        Write-InformationMessage "Testing connection to $($server.Servername)" 
        if (Test-Connection $server.Servername -count 1 -Quiet){
            Write-InformationMessage "Connection to $($server.Servername) successful"
        }
        else {
            Write-ErrorMessage -Message "Connection to $($server.Servername) unsuccessful! Possible connection issues with site."
            $ErrorCount ++
            $FatalErrorCount += $server.FatalError
        }
    }

    if ($FatalErrorCount -ge 1){
        return $false
    }
    else {
        return $true
    }

}
