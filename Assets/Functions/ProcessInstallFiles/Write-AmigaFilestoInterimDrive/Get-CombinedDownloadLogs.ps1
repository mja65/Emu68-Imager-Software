function Get-CombinedDownloadLogs {
    param (
        $Path
    )
    
    # $Path = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\ParallelRunDebugLogs"

    $FileGroups = Get-ChildItem -Path $Path -File | Group-Object {
        if ($_.Name -match 'Thread(\d+)') { [int]$Matches[1] } else { 0 }
    }
        
    $Results = foreach ($Group in $FileGroups) {
        # Read lines from all files that share this thread number in their filename
        $ThreadLines = foreach ($File in $Group.Group) {
            [System.IO.File]::ReadLines($File.FullName)
        }
        foreach ($line in $ThreadLines) {
            if ($line.Contains(';')) {
                $time, $thread, $message = $line.Split(';', 3)
                $normalisedTime = $time -replace '^(.+):(\d+)$', '$1.$2'
                [PSCustomObject]@{
                    Time    = [datetime]$normalisedTime
                    Thread  = $thread
                    Message = $message
                }
            }
        }
    }

    return $Results | Sort-Object Thread, Time

}