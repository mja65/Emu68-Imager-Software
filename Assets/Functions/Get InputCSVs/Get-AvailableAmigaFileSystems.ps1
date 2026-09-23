function Get-AvailableAmigaFileSystems {
    param (
        [Switch]$FileSystemsFLAG,
        [Switch]$DosTypesFLAG,
        [Switch]$FilesystemsbyDosTypesFLAG
    )
     
    $ListofFileSystemstoCheck = @()
    
    (Get-ChildItem $Script:Settings.DownloadedFileSystems -file -Recurse -force).FullName | ForEach-Object {
        $ListofFileSystemstoCheck += $_
    }

    (Get-ChildItem $Script:Settings.DefaultAmigaFileSystemLocation -file -Recurse -force).FullName | ForEach-Object {
        $ListofFileSystemstoCheck += $_
    }

    $FoundFileSystems = [System.Collections.Generic.List[PSCustomObject]]::New()
       
    $HashTableforFileSystemstoCheck = @{} # Clear Hash

    #Identify Unique FileSystems Available

    foreach ($FileSystem in $ListofFileSystemstoCheck){
        if ($FileSystem){
            $FileSystemHash = Get-FileHash -Path $filesystem -Algorithm MD5
            if (-not ($HashTableforFileSystemstoCheck[$FileSystemHash.Hash])){
                $HashTableforFileSystemstoCheck.Add(($FileSystemHash.Hash),$FileSystem)
            }           
        }
    }

    foreach ($FileSystemtoFind in (Get-InputFileCSV -CSV 'FileSystems')){
        if ($HashTableforFileSystemstoCheck[$FileSystemtoFind.Hash]){
            $FoundFileSystems += [PSCustomObject]@{
                FileSystemName = $FileSystemtoFind.FilesystemName
                DosType = $FileSystemtoFind.DosType
                FileSystemDescription = $FileSystemtoFind.Description
                FileSystemPath = ($HashTableforFileSystemstoCheck[$FileSystemtoFind.Hash])
            }        
        }
    }

    if ($FileSystemsFLAG){
        return $FoundFileSystems
    }
    else {
        $FilesystemsbyDosTypes = [System.Collections.Generic.List[PSCustomObject]]::New()
        $FoundFileSystems | ForEach-Object {
            $CountofVariables = ([regex]::Matches($_.DosType, "," )).count
            if ($CountofVariables -gt 0){
                $Counter = 0
                do {                    
                    $FilesystemsbyDosTypes += [PSCustomObject]@{
                        DosType = (($_.DosType -split ',')[$Counter])
                        FileSystemPath = $_.FileSystemPath 
                    }      
                    $counter ++
                }until (
                    $Counter -eq ($CountofVariables+1)
                )
    
            }
            else {
                if ($_.DosType -ne ""){
                    $FilesystemsbyDosTypes  += [PSCustomObject]@{
                        DosType = $_.DosType
                        FileSystemPath = $_.FileSystemPath 
                    }
                }
            }
        }
        if ($FilesystemsbyDosTypesFLAG) {
            return $FilesystemsbyDosTypes

        }
        elseif ($DosTypesFLAG) {
            return ($FilesystemsbyDosTypes.DosType)
        }
    }
}

