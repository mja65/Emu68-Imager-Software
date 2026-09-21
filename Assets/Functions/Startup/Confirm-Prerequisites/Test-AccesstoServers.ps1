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
   
    $ErrorCount = 0
    $FatalErrorCount = 0

    Write-InformationMessage -Message "Testing accessibility of servers. Note, this is an indication only" -NewLineAfter

    foreach ($Server in $ServerList) {
        write-informationMessage -Message "Testing connection to $($server.Servername)"
        if ($Server.ServerName -eq "ftp2.grandis.nu") {
            $webPage = Invoke-WebRequest -Uri "https://grandis.nu:444/quick.php" -UseBasicParsing
            if ($webPage.Content -eq "false"){
                write-informationMessage -Message "Connection to $($server.Servername) successful"
            }
            else {
                Write-WarningMessage -Message "Connection to $($server.Servername) unsuccessful! Possible connection issues with site."
                $ErrorCount ++
                $FatalErrorCount += $server.FatalError
            }
        }
        else {
            if (Test-Connection $server.Servername -count 1 -Quiet){
                write-informationMessage -Message "Connection to $($server.Servername) successful"
            }
            else {
                Write-WarningMessage -Message "Connection to $($server.Servername) unsuccessful! Possible connection issues with site."
                $ErrorCount ++
                $FatalErrorCount += $server.FatalError
            }
        } 
    }

    if ($FatalErrorCount -ge 1){
        return $false
    }
    else {
        return $true
    }

}