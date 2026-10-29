function Compare-CDHashes {
    param (
        $PathtoADFFiles,
        $MaximumFilestoCheck
    )

    $Msg_Header ='Finding ADFs'    
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

#    $PathtoADFFiles = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\UserFiles\InstallMedia"
#    $MaximumFilestoCheck = 40

    $PathtoADFFiles = [System.IO.Path]::GetFullPath(($PathtoADFFiles.TrimEnd([System.IO.Path]::DirectorySeparatorChar)))

    $ListofADFFilestoCheck = Get-ChildItem $PathtoADFFiles -force -Recurse | Where-Object {($_.Name -match '.iso' -or $_.Name -match '.lha')}

    $TotalNumberFilesParent = ($ListofADFFilestoCheck | Where-Object {$_.DirectoryName -eq $PathtoADFFiles.TrimEnd('\') } | Measure-Object).count
    $TotalNumberFiles = ($ListofADFFilestoCheck | Measure-Object).count

    if ($TotalNumberFilesParent -gt $MaximumFilestoCheck){
        $null = Show-WarningorError -BoxTypeError -ButtonType_OK -Msg_Body $Msg_Body_ExceedLimitParent -Msg_Header $Msg_Header_ExceedLimitParent
        return
    }
   
    if ($TotalNumberFiles -gt $MaximumFilestoCheck){
        $null = Show-WarningorError -BoxTypeWarning  -ButtonType_OK -Msg_Body $Msg_Body_ExceedLimit -Msg_Header $Msg_Header_ExceedLimit
        $ListofADFFilestoCheck = $ListofADFFilestoCheck |  Where-Object {$_.DirectoryName -eq $PathtoADFFiles.TrimEnd('\')} 
    }


    $RequiredInstallMedia = Get-OSSources | Select-Object SourceLocation, InstallMediaFriendlyName, @{
        Name = 'SourceType'
        Expression = { if ($_.SourceType -eq 'ArchiveInArchive') { 'Archive' } else { $_.SourceType } }
    } -Unique


    $RequiredInstallMediaandHashes = (Get-InputFileCSV -CSV 'InstallMediaHashes').where{($Script:GUIActions.KickstartVersiontoUse -in $_.WorkbenchVersion.Split(',').Trim())}
    
    $CDFilestoCheck = $ListofADFFilestoCheck.where({$_.Name -match '.iso'})   
    $ArchivestoCheck = $ListofADFFilestoCheck.where({$_.Name -match '.lha'})

    
    $MatchedInstallMedia = [System.Collections.Generic.List[PSCustomObject]]::new()

    Foreach ($RequiredItem in $RequiredInstallMediaandHashes) {
        If ($RequiredItem.TypeofCheck -eq "FileCheck"){
            $FilestoCheck = $RequiredItem.FilesChecked.Split(",")
            $FileDetails  = $RequiredItem.FileCheckDetails.Split(",")
            $FileSizeTotal = [long]$FileDetails[0]
            $FileCount     = [int]$FileDetails[2]
            Foreach ($CD in $CDFilestoCheck) {
                $FileName = $CD.FullName
                $FilesonCD = [ISOExtractor]::GetEntries($FileName)
                $ItemsFound = $FilesonCD | Where-Object { $_.Path -in $FilestoCheck }
                $SizeofItemsFound = ($ItemsFound.Size | ForEach-Object { [int]$_ } | Measure-Object -Sum).Sum
                $NumberofItemsFound = $ItemsFound.Count 
                if ($NumberofItemsFound -eq $FileCount -and $SizeofItemsFound -eq $FileSizeTotal){
                    $MatchedInstallMedia.Add([PSCustomObject]@{
                        Path         = $FileName 
                        Hash         = "N/A - Matched through files"
                        ADF_Name     = $RequiredItem.ADF_Name
                        FriendlyName = $RequiredItem.FriendlyName
                        InstallMedia = $RequiredItem.InstallMedia
                        Source       = $RequiredItem.ADFSource 
                        IsMatched    = $true
                    })
                    break # Exit inner loop immediately once matched
                }
            }
        }
        elseif ($RequiredItem.TypeofCheck -eq "Hash"){
            Foreach ($Archive in $ArchivestoCheck) {
                $FileName = $Archive.FullName
                $FileHash = (Get-FileHash -LiteralPath $FileName -Algorithm MD5).Hash.ToUpperInvariant()   
                If ($RequiredItem.Hash -eq $FileHash){
                    $MatchedInstallMedia.Add([PSCustomObject]@{
                        Path         = $FileName 
                        Hash         = $RequiredItem.Hash
                        ADF_Name     = $RequiredItem.ADF_Name
                        FriendlyName = $RequiredItem.FriendlyName
                        InstallMedia = $RequiredItem.InstallMedia
                        Source       = $RequiredItem.ADFSource 
                        IsMatched    = $true
                    })
                    break # Exit inner loop immediately once matched
                }
            }
        }
    }
                
    $RequiredInstallMedia.where({ (-not $_.SourceLocation -in $MatchedInstallMedia.ADF_Name)}).foreach({
        $MatchedInstallMedia += [PSCustomObject]@{
            Hash = '' 
            Path = ''
            ADF_Name = $_.SourceLocation
            FriendlyName = $_.InstallMediaFriendlyName
            InstallMedia = $null
            Source = $null
            IsMatched = $false      
        }
    })
    
    return $MatchedInstallMedia
    
}  