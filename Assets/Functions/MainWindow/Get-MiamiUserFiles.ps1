function Get-MiamiUserFiles {
    param (
        $MiamiFilesPath,
        $DestinationPath

    )
    
    #$MiamiFilesPath = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\UserFiles\Miami"
    #$DestinationPath = "\disk6"
    
    $ListofFilestoFind = @(
        [PSCustomObject]@{Name="MIAMI.KEY1"; SizeBytes=2048}
        [PSCustomObject]@{Name="MIAMI.KEY2"; SizeBytes=2048}
        [PSCustomObject]@{Name="MIAMIDX.KEY"; SizeBytes=4096}
    )
    
    $HSTCommands = [System.Collections.Generic.List[PSCustomObject]]::New()
    
    $ListofFilestoFind | ForEach-Object {
        $File = Get-Item -Path (Join-Path $MiamiFilesPath $_.Name) -ErrorAction SilentlyContinue
        if (-not ($null -ne $File -and $File.Length -eq $_.SizeBytes)) {
           break
        }
        else {
            $HSTCommands += [PSCustomObject]@{
                Command =  "fs copy `"$File`" `"$DestinationPath\Programs\Miami`" --makedir TRUE --uaemetadata UaeFsDb --force TRUE"
                Sequence = 1  
            }
        } 
    }

    return $HSTCommands
}
# Get-MiamiUserFiles -MiamiFilesPath "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\UserFiles\Miami" -DestinationPath "\disk6"
