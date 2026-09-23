function Compare-ADFHashes {
    param (
        $PathtoADFFiles,
        $MaximumFilestoCheck
    )

    #$MaximumFilestoCheck = 400   
    #$PathtoADFFiles = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\UserFiles\InstallMedia"
    
    $Msg_Header ='Finding Install Media'    

$Msg_Body = @"
Searching folder '$PathtoADFFiles' for valid Install files (e.g. ADFs, CDs, etc.). 
"@

    $Msg_Header_ExceedLimitParent = 'Exceeded file limits!'   
$Msg_Body_ExceedLimitParent = @"
Search is limited to a maximum of $MaximumFilestoCheck files! Select a different path 
with less files or move the install files into the default 
'UserFiles\InstallMedia\' folder in your install path for the tool
and select this path to scan. 
"@

    $Msg_Header_ExceedLimit ='Exceeded file limits!'   

$Msg_Body_ExceedLimit = @"
Search is limited to a maximum of 500 files! The current path (with no sub-folders) will be matched.

If this does not find your installation files (e.g. ADFs, CDs, 
etc.) either select a different path with less files or move 
the files into the default 'UserFiles\InstallMedia\' folder 
in your install path for the tool and select this path to scan. 
"@

    $null = Show-WarningorError -Msg_Body $Msg_Body -Msg_Header $Msg_Header -BoxTypeNone -ButtonType_OK

    $RequiredSizeInBytes = 901120
    
    # 1. Load the data sources first
   
    # 2. Build the target list and look up the FriendlyName dynamically from the priority table
    $FileNamesToFind = (Get-OSSources).where{($_.SourceType -eq 'ADF')} 
    
    $CandidateFiles = Get-ChildItem -Path $PathtoADFFiles  -Recurse -File | Where-Object { $_.Length -eq $RequiredSizeInBytes }
    $CandidateFilesParent = $CandidateFiles | Where-Object { $_.DirectoryName -eq $PathtoADFFiles  }
    $TotalNumberFiles = $CandidateFiles.count
    $TotalNumberFilesParent = $CandidateFilesParent.count
    
    if ($TotalNumberFilesParent -gt $MaximumFilestoCheck){
        $null = Show-WarningorError -BoxTypeError -ButtonType_OK -Msg_Body $Msg_Body_ExceedLimitParent -Msg_Header $Msg_Header_ExceedLimitParent
        return
    }
        
    if ($TotalNumberFiles -gt $MaximumFilestoCheck){
        $null = Show-WarningorError -BoxTypeWarning  -ButtonType_OK -Msg_Body $Msg_Body_ExceedLimit -Msg_Header $Msg_Header_ExceedLimit
        $ListofADFFilestoCheck = $ListofADFFilestoCheck |  Where-Object {$_.DirectoryName -eq $PathtoADFFiles.TrimEnd('\')} 
    }
       
    $FinalResults = [System.Collections.Generic.List[PSObject]]::new()
    $HashCache = @{}
    
    foreach ($TargetName in $FileNamesToFind) {
        $RulesForTarget = (Get-InputFileCSV -CSV 'InstallMediaHashes') | Where-Object { $_.ADF_Name -eq $TargetName.SourceLocation } | Sort-Object Sequence
        
        # FIXED: Capture targets that have NO rules at all in the Final Results table
        if ($RulesForTarget.Count -eq 0) {
            $FinalResults.Add([PSCustomObject]@{
                Hash         = $null
                Path         = $null
                ADF_Name     = $TargetName.SourceLocation
                FriendlyName = $TargetName.InstallMediaFriendlyName
                InstallMedia = $null
                Source       = $null
                Sequence     = $null
                IsMatched    = $false
            })
            continue
        }
    
        $BestMatchForThisTarget = $null
        $BestSequence = [int]::MaxValue # Track best rank found so far for this file
    
        # OPTIMIZED: Loop through files on the outside so we only evaluate each file once per target
        foreach ($File in $CandidateFiles) {
            $FilePath = $File.FullName
    
            # Check if we already calculated this file's hash previously
            if ($HashCache.ContainsKey($FilePath)) {
                $FileHash = $HashCache[$FilePath]
            } else {
                $FileHash = (Get-FileHash -LiteralPath $FilePath -Algorithm MD5).Hash.ToUpper()
                $HashCache[$FilePath] = $FileHash
            }
    
            # Check if this file's hash matches ANY rule for this target
            $MatchedRule = $RulesForTarget | Where-Object { $_.Hash.ToUpper() -eq $FileHash }
    
            if ($null -ne $MatchedRule) {
                $CurrentSequence = [int]$MatchedRule.Sequence
    
                # If this is a better priority match than what we already found
                if ($CurrentSequence -lt $BestSequence) {
                    $BestSequence = $CurrentSequence
                    $BestMatchForThisTarget = [PSCustomObject]@{
                        Hash         = $FileHash
                        Path         = $FilePath
                        ADF_Name     = $TargetName.SourceLocation
                        FriendlyName = $MatchedRule.FriendlyName
                        InstallMedia = $MatchedRule.InstallMedia
                        Source       = $MatchedRule.ADFSource
                        Sequence     = $CurrentSequence
                        IsMatched    = $true
                    }
    
                    # SHORT-CIRCUIT: If it's Sequence 1, stop checking other files on disk!
                    if ($BestSequence -eq 1) {
                        break 
                    }
                }
            }
        }
    
        # Append the result (found or not found placeholder)
        if ($null -ne $BestMatchForThisTarget) {
            $FinalResults.Add($BestMatchForThisTarget)
        } else {
            $FinalResults.Add([PSCustomObject]@{
                Hash         = $null
                Path         = $null
                ADF_Name     = $TargetName.SourceLocation
                FriendlyName = $TargetName.InstallMediaFriendlyName
                InstallMedia = $null
                Source       = $null
                Sequence     = $null
                IsMatched    = $false
            })
        }        
    }

    return $FinalResults  

}