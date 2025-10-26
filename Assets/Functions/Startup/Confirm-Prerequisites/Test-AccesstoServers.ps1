function Test-AccesstoServers {
    param (
        
    )

    $ServerList = [System.Collections.Generic.List[PSCustomObject]]::New()
     
    $ServerList += [PSCustomObject]@{
       ServerName = "github.com"
        FatalError = 1
    }
    
    $ServerList += [PSCustomObject]@{
        ServerName = "aminet.net"
        FatalError = 1
    }

    $ServerList += [PSCustomObject]@{
        ServerName = "ftp2.grandis.nu"
        FatalError = 0.5
    }

    $ServerList += [PSCustomObject]@{
        ServerName = "dropbox.com"
        FatalError = 0.5
    }

    $ServerList += [PSCustomObject]@{
        ServerName = "dopus.free.fr"
        FatalError = 0
    }


    $ServerList += [PSCustomObject]@{
        ServerName = "ibrowse-dev.net"
        FatalError = 0
    }


    $ErrorCount = 0
    $FatalErrorCount = 0

    foreach ($Server in $ServerList) {
        Write-InformationMessage "Testing connection to $($server.Servername)" 
        if (Test-Connection $server.Servername -count 1){
            Write-InformationMessage "Connection to $($server.Servername) successful"
        }
        else {
            Write-Error "Connection to $($server.Servername) unsuccessful!"
            $ErrorCount ++
            $FatalErrorCount += $server.FatalError
        }
    }

    if ($FatalErrorCount -gt 0){
        return $false
    }
    else {
        return $true
    }

}

