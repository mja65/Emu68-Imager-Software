Function Update-UAEFSDB {
    param (
        $Path,
        $UAEFSEntry
    )
    
    #$path = "\\?\C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\InterimAmigaDrives\System\S\CheckScreenModeandChipset.rexx"

    $ParentFolder = split-path $Path -Parent    
    $UAEFSDBPath =  [System.IO.Path]::Combine($ParentFolder, "_UAEFSDB.___") 
    $FileName = split-path $Path -Leaf

    if ([System.IO.File]::Exists($UAEFSDBPath)) {
        [byte[]]$DatabaseBytes = [System.IO.File]::ReadAllBytes($UAEFSDBPath)
        $RecordUpdated = $false
        
        for ($i = 0; $i -lt $DatabaseBytes.Length; $i += 600) {
            if (($i + 600) -le $DatabaseBytes.Length) {
                $NameBytes = $DatabaseBytes[($i + 5)..($i + 5 + 256)]
                $NullIndex = [System.Array]::IndexOf($NameBytes, [byte]0)
                $Length = if ($NullIndex -ge 0) { $NullIndex } else { $NameBytes.Length }
                
                if ($Length -gt 0) {
                    $ExistingName = [System.Text.Encoding]::ASCII.GetString($NameBytes, 0, $Length)
                    if ($ExistingName -eq $FileName) {
                        [System.Array]::Copy($UAEFSEntry, 0, $DatabaseBytes, $i, 600)
                        $RecordUpdated = $true
                        break
                    }
                }
            }
        }

        if ($RecordUpdated) {
            [System.IO.File]::WriteAllBytes($UAEFSDBPath, $DatabaseBytes)
        } else {
            $Stream = [System.IO.File]::Open($UAEFSDBPath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write)
            $Stream.Write($UAEFSEntry, 0, $UAEFSEntry.Length)
            $Stream.Close()
        }
    } else {
        [System.IO.File]::WriteAllBytes($UAEFSDBPath, $UAEFSEntry)
    }
    
}