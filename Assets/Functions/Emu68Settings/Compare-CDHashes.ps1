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

    # | Where-object {$_.SourceType -in @('Archive','CD')}

    $RequiredInstallMedia = Get-OSSources | Select-Object SourceLocation, InstallMediaFriendlyName, @{
        Name = 'SourceType'
        Expression = { if ($_.SourceType -eq 'ArchiveInArchive') { 'Archive' } else { $_.SourceType } }
    } -Unique

    $RequiredInstallMediaandHashes = @{}

    (Get-InputFileCSV -CSV 'InstallMediaHashes').where{($Script:GUIActions.KickstartVersiontoUse -in $_.WorkbenchVersion.Split(',').Trim())}.foreach({
        $Check = $null
        If ($_.TypeofCheck -eq "Hash"){
            $Check = "Hash;$($_.Hash)"
        }    
        elseIf ($_.TypeofCheck -eq "FileCheck"){
            $Check = "FileCheck;$($_.FileCheckDetails)"            
        }          
        $RequiredInstallMediaandHashes[$Check] = [PSCustomObject]@{       
            Sequence = $_.Sequence
            ADF_Name = $_.ADF_Name
            FriendlyName = $_.FriendlyName
            TypeofCheck = $_.TypeofCheck
            InstallMedia = $_.InstallMedia
            Hash = $_.Hash
            FilesChecked = $_.FilesChecked
            FileCheckDetails = $_.FileCheckDetails
            ADFSource = $_.ADFSource            
        }          
    })

    $CDFileSearch = @()
    
    ((Get-InputFileCSV -CSV 'InstallMediaHashes').where{($Script:GUIActions.KickstartVersiontoUse -in $_.WorkbenchVersion.Split(',').Trim())}).foreach({
        if ($_.TypeofCheck -eq "FileCheck"){
            $7zStringtoUse = $null
            for ($i = 0; $i -lt ($_.FilesChecked -split ',').count; $i++) {
                $7zStringtoUse += "`"-ir!$(($_.FilesChecked -split ',')[$i])`" "
            }                          
            $CDFileSearch += $7zStringtoUse                
                         
        }
    })
    
    $CDFilestoCheck = $ListofADFFilestoCheck.where({$_.Name -match '.iso'})   
    $MatchedInstallMedia = [System.Collections.Generic.List[PSObject]]::new()

    :Cdloop Foreach ($CD in $CDFilestoCheck) {
        $FileName = $CD.FullName
        foreach ($CommandString in $CDFileSearch) {
            $FileCheckTest = & $Script:ExternalProgramSettings.SevenZipFilePath l $filename ($CommandString.Split(' '))     
            $LinetoCheck= $FileCheckTest[$FileCheckTest.Count-1]
            if ($LinetoCheck -match '^(?:\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})?\s*(\d+)\s+(\d+)\s+(\d+)\s+files') {
                $OutputLine = "$($matches[1]),$($matches[2]),$($matches[3])"
                if ($RequiredInstallMediaandHashes["FileCheck;$OutputLine"]){
                    $FoundCD = [PSCustomObject]@{
                        Hash = $RequiredInstallMediaandHashes["FileCheck;$OutputLine"].Hash
                        Path = $FileName 
                        ADF_Name = $RequiredInstallMediaandHashes["FileCheck;$OutputLine"].ADF_Name
                        FriendlyName = $RequiredInstallMediaandHashes["FileCheck;$OutputLine"].FriendlyName
                        InstallMedia = $RequiredInstallMediaandHashes["FileCheck;$OutputLine"].InstallMedia
                        Source = $RequiredInstallMediaandHashes["FileCheck;$OutputLine"].ADFSource    
                        IsMatched = $true    
#                       Sequence = $RequiredInstallMediaandHashes["FileCheck;$OutputLine"].Sequence
#                       TypeofCheck = $RequiredInstallMediaandHashes["FileCheck;$OutputLine"].TypeofCheck
#                       FilesChecked = $RequiredInstallMediaandHashes["FileCheck;$OutputLine"].FilesChecked
#                       FileCheckDetails = $RequiredInstallMediaandHashes["FileCheck;$OutputLine"].FileCheckDetails
                    }
                    If ($RequiredInstallMediaandHashes["FileCheck;$OutputLine"].Sequence -eq 1){
                        break CDLoop
                    }
                }
            }
        }
        $FileHash = (Get-FileHash -LiteralPath $FileName -Algorithm MD5).Hash.ToUpper()
        if (($RequiredInstallMediaandHashes["Hash;$FileHash"]) -and ($RequiredInstallMediaandHashes["Hash;$FileHash"].Sequence -gt $MatchedLine.Sequence)){
            $FoundCD = [PSCustomObject]@{
                Hash = $FileHash
                Path = $FileName 
                ADF_Name = $RequiredInstallMediaandHashes["Hash;$FileHash"].ADF_Name
                FriendlyName = $RequiredInstallMediaandHashes["Hash;$FileHash"].FriendlyName
                InstallMedia = $RequiredInstallMediaandHashes["Hash;$FileHash"].InstallMedia
                Source = $RequiredInstallMediaandHashes["Hash;$FileHash"].ADFSource 
                IsMatched = $true      
#               Sequence = $RequiredInstallMediaandHashes["Hash;$FileHash"].Sequence
#               TypeofCheck = $RequiredInstallMediaandHashes["Hash;$FileHash"].TypeofCheck
#               FilesChecked = $null
#               FileCheckDetails = $null
            }
            If ($RequiredInstallMediaandHashes["Hash;$FileHash"].Sequence -eq 1){
                break CDLoop
            }                                
        }
    }  
    
    $MatchedInstallMedia += $FoundCD 
    
    $ArchivestoCheck = $ListofADFFilestoCheck.where({$_.Name -match '.lha'})
    
    $FoundADFNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    Foreach ($Archive in $ArchivestoCheck) {
        $FileName = $Archive.FullName
        $FileHash = (Get-FileHash -LiteralPath $FileName -Algorithm MD5).Hash.ToUpper()
        if ($RequiredInstallMediaandHashes["Hash;$FileHash"]){
            $TargetADF = $RequiredInstallMediaandHashes["Hash;$FileHash"]
            
            if ($FoundADFNames.Contains($TargetADF.ADF_Name)) {
                continue
            }
            $MatchedInstallMedia += [PSCustomObject]@{
                Hash = $FileHash
                Path = $FileName 
                ADF_Name = $TargetADF.ADF_Name
                FriendlyName = $TargetADF.FriendlyName
                InstallMedia = $TargetADF.InstallMedia
                Source = $TargetADF.ADFSource  
                IsMatched = $true     
#                Sequence = $TargetADF.Sequence
 #               TypeofCheck = $TargetADF.TypeofCheck
  #              FilesChecked = $null
   #             FileCheckDetails = $null
            }
            [void]$FoundADFNames.Add($TargetADF.ADF_Name)                       
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
            IsMatched = $true      
        }
    })
    
    return $MatchedInstallMedia
    
}  


