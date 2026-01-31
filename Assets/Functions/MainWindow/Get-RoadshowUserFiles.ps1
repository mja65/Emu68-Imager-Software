function Get-RoadshowUserFiles {
    param (
        $RoadshowFilesPath,
        $DestinationPath
    )
    
    #$RoadshowFilesPath = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\UserFiles\Roadshow"
    
    $HSTCommands = [System.Collections.Generic.List[PSCustomObject]]::New()
    
    $RoadshowPath = (Get-ChildItem -Path $RoadshowFilesPath | Where-Object {$_.name -match "Roadshow-1." -and [System.IO.Path]::GetExtension($_.name)-eq ".lha"} | Select-Object -First 1)
    $RoadshowName = [System.IO.Path]::GetFileNameWithoutExtension($RoadshowPath.Name)
    
    $Check = & $([System.IO.Path]::GetFullPath("$($Script:ExternalProgramSettings.HSTImagerPath)")) fs d "$($RoadshowPath.FullName)\$RoadshowName\Workbench\Libs\020\bsdsocket.library"
    
    $SummaryLine = $Check | Select-String -Pattern "\d+ files?"
    if ($SummaryLine -match '(?<Count>\d+)\s+files?') {
        $FileCount = [int]$Matches['Count']
    }
    
    If ($FileCount -eq 1){
        $HSTCommands += [PSCustomObject]@{
            Command = "fs extract `"$($RoadshowPath.FullName)\$RoadshowName\Workbench\Libs\020\bsdsocket.library`" `"$DestinationPath\Libs`" --makedir TRUE --uaemetadata UaeFsDb --force TRUE"
            Sequence = 1
        }
        
    }
    
    return $HSTCommands

}  