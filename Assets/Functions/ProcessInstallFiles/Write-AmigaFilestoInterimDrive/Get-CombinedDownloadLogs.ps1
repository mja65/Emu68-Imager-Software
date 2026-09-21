function Get-CombinedDownloadLogs {
    param (
        $Path
    )
    
    $SortedLogFiles = Get-ChildItem -Path $Path -File | Sort-Object -Property FullName

    $Results = foreach ($File in $SortedLogFiles) {
        $Lines = [System.IO.File]::ReadLines($File.FullName)
        foreach ($line in $Lines) {
            if ($line.Contains(';')) {
                $time, $thread, $message = $line.Split(';', 3)
                [PSCustomObject]@{
                    Time    = $time
                    Thread  = $thread
                    Message = $message
                }
            }
        }
    }

    return $Results 
    
}
