function Compare-KickstartHashes {
    param (
        $PathtoKickstartFiles,
        $MaximumFilestoCheck
    )
    
    
    $Msg_Header ='Finding Kickstart'    
    $Msg_Body = @"
Searching folder '$PathtoKickstartFiles' for valid Kickstart file. Depending on the size of the folder you selected this may take some time. 
"@

$Msg_Header_ExceedLimitParent ='Exceeded file limits!'   
$Msg_Body_ExceedLimitParent = @"
Search is limited to a maximum of $MaximumFilestoCheck files! Select a different path 
with less files or move the Kickstart into the default 
'UserFiles\Kickstarts\' folder in your install path for the tool
and select this path to scan. 

"@

    $Msg_Header_ExceedLimit ='Exceeded file limits!'   
    $Msg_Body_ExceedLimit = @"
Search is limited to a maximum of $MaximumFilestoCheck files! The current path (with no sub-folders) will be matched.

If this does not find your Kickstart file either select a different path 
with less files or move the Kickstart into the default 
'UserFiles\Kickstarts\' folder in your install path for the tool
and select this path to scan. 

"@

    $null = Show-WarningorError -BoxTypeNone -ButtonType_OK -Msg_Header $Msg_Header -Msg_Body $Msg_Body

    #  $PathtoKickstartFiles = 'C:\Users\Matt\OneDrive\Documents\DiskPartitioner\UserFiles\Kickstarts'
    #  $MaximumFilestoCheck = 40
          
    $ListofKickstartFilestoCheck = Get-ChildItem $PathtoKickstartFiles -file -force -Recurse | Where-Object {($_.Length -eq 524288 -or $_.Length -eq  524299 -or $_.Length -eq 262144)}

    $TotalNumberFilesParent = ($ListofKickstartFilestoCheck | Where-Object { $_.DirectoryName -eq $PathtoKickstartFiles.TrimEnd('\') } | Measure-Object).count
    $TotalNumberFiles = ($ListofKickstartFilestoCheck | Measure-Object).count


    if ($TotalNumberFilesParent -gt $MaximumFilestoCheck){
        $null = Show-WarningorError -BoxTypeError -ButtonType_OK -Msg_Body $Msg_Body_ExceedLimitParent -Msg_Header $Msg_Header_ExceedLimitParent
        return
    }
    if ($TotalNumberFiles -gt $MaximumFilestoCheck){
        $null = Show-WarningorError -BoxTypeWarning -ButtonType_OK -Msg_Body $Msg_Body_ExceedLimit -Msg_Header $Msg_Header_ExceedLimit
        $ListofKickstartFilestoCheck = ($ListofKickstartFilestoCheck | Where-Object {$_.DirectoryName -eq $PathtoKickstartFiles.TrimEnd('\')})
    }

    # $Script:GUIActions.KickstartVersiontoUse = 3.1

    $AllROMHashes = Get-InputFileCSV -CSV 'ROMHashes'

    $KickstartHashestoFind = @{}
    $WHDLoadKickstartHashestoFind = @{}
    
    foreach ($Row in $AllROMHashes) {
        $Versions = $Row.KickstartVersion.Split(',').Trim()
        if ($Script:GUIActions.KickstartVersiontoUse -in $Versions) {
            $KickstartHashestoFind[$Row.Hash] = $Row
        }
        if ($Row.WHDLoadName) {
            $WHDLoadKickstartHashestoFind[$Row.Hash] = $Row
        }
    }

    $FoundKickstarts = [System.Collections.Generic.List[PSCustomObject]]::New()
    $FoundKickstartROM = $false
    $FoundEncryptedKickstartROM = $false
    $WHDLoadKickstartROMCounter = 0
    $TotalWHDLoadRomstoFind = $WHDLoadKickstartHashestoFind.Count
    $FoundWHDLoadHashes = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    foreach ($File in $ListofKickstartFilestoCheck) {
        if ($FoundKickstartROM -and ($WHDLoadKickstartROMCounter -eq $TotalWHDLoadRomstoFind)) {
            break
        }
        $FileHash = (Get-FileHash -LiteralPath $File.FullName -Algorithm MD5).Hash
    
        $MatchedObject = $null
        $IsKickstartMatch = (-not $FoundKickstartROM) -and $KickstartHashestoFind.ContainsKey($FileHash) -and $KickstartHashestoFind[$FileHash].IncludeorExclude -eq "Include"
        $IsEncryptedKickstartMatch = (-not $FoundEncryptedKickstartROM) -and $KickstartHashestoFind.ContainsKey($FileHash) -and $KickstartHashestoFind[$FileHash].IncludeorExclude -eq "Exclude"
        $IsWHDLoadMatch   = ($WHDLoadKickstartROMCounter -lt $TotalWHDLoadRomstoFind) -and $WHDLoadKickstartHashestoFind.ContainsKey($FileHash) -and $FoundWHDLoadHashes.Add($FileHash) 
        if ($IsKickstartMatch) {
            $FoundKickstartROM = $true
            $MatchData = $KickstartHashestoFind[$FileHash]
            $MatchedObject = [PSCustomObject]@{
                KickstartVersion = $Script:GUIActions.KickstartVersiontoUse
                FriendlyName      = $MatchData.FriendlyName
                Sequence          = $MatchData.Sequence 
                IncludeorExclude  = $MatchData.IncludeorExclude
                ExcludeMessage    = $MatchData.ExcludeMessage
                Fat32Name         = $MatchData.Fat32Name
                KickstartPath     = $File.FullName
                WHDLoadName       = $MatchData.WHDLoadName
                Status            = "Found"
            }
        }
        if ($IsEncryptedKickstartMatch) {
            $FoundEncryptedKickstartROM = $true
            $MatchData = $KickstartHashestoFind[$FileHash]
            $MatchedObject = [PSCustomObject]@{
                KickstartVersion = $Script:GUIActions.KickstartVersiontoUse
                FriendlyName      = $MatchData.FriendlyName
                Sequence          = $MatchData.Sequence 
                IncludeorExclude  = $MatchData.IncludeorExclude
                ExcludeMessage    = $MatchData.ExcludeMessage
                Fat32Name         = $MatchData.Fat32Name
                KickstartPath     = $File.FullName
                WHDLoadName       = $MatchData.WHDLoadName
                Status            = "Found"
            }
        }
        if ($IsWHDLoadMatch) {
            $WHDLoadKickstartROMCounter++
            $MatchData = $WHDLoadKickstartHashestoFind[$FileHash]
            if ($MatchedObject) {
                $MatchedObject.WHDLoadName = $MatchData.WHDLoadName
            } 
            else {
                $MatchedObject = [PSCustomObject]@{
                    KickstartVersion = $null
                    FriendlyName      = $MatchData.FriendlyName
                    Sequence          = $MatchData.Sequence 
                    IncludeorExclude  = $MatchData.IncludeorExclude
                    ExcludeMessage    = $MatchData.ExcludeMessage
                    Fat32Name         = $MatchData.Fat32Name
                    KickstartPath     = $File.FullName
                    WHDLoadName       = $MatchData.WHDLoadName
                    Status            = "Found"
                }
            }
        }
        if ($null -ne $MatchedObject) {
            $FoundKickstarts.Add($MatchedObject)
        }
    }
   
foreach ($Hash in $WHDLoadKickstartHashestoFind.Keys) {
    if (-not $FoundWHDLoadHashes.Contains($Hash)) {
        $MissingData = $WHDLoadKickstartHashestoFind[$Hash]
        
        $FoundKickstarts.Add([PSCustomObject]@{
            KickstartVersion = $null
            FriendlyName      = $MissingData.FriendlyName
            Sequence          = $MissingData.Sequence 
            IncludeorExclude  = $MissingData.IncludeorExclude
            ExcludeMessage    = $MissingData.ExcludeMessage
            Fat32Name         = $MissingData.Fat32Name
            KickstartPath     = $null          
            WHDLoadName       = $MissingData.WHDLoadName
            Status            = "Not Found"     
        })
    }
}

    If ($FoundKickstartROM){
        return $FoundKickstarts.where({$_.IncludeorExclude -ne "Exclude"})

    }
    else {
        return $FoundKickstarts
    }
    
}   