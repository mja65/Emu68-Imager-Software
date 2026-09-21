function Check-RoadshowUserFiles {
        param (
            $RoadshowFilesPath
         
        )
    
        # $RoadshowFilesPath = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\UserFiles\ExistingApplications"
           
        $RoadshowPath = (Get-ChildItem -Path $RoadshowFilesPath -Recurse | Where-Object {$_.name -match "Roadshow-1." -and [System.IO.Path]::GetExtension($_.name)-eq ".lha"} | Select-Object -First 1)
    
        if (-not ($RoadshowPath)){
            return $false
        }

        $FileCheckTest = & $Script:ExternalProgramSettings.SevenZipFilePath l "$($RoadshowPath.FullName)" -r "bsdsocket.library"
        $IsResult = $FileCheckTest.where({$_ -match "Workbench\\Libs\\020\\bsdsocket\.library"})

        If (-not $IsResult){
            return $false
        }

        $ParsedFiles = $FileCheckTest | ForEach-Object {
            if ($_ -match '^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s+(\S+)\s+(\d+)\s+(\d+)\s+(.*)$') {
                [PSCustomObject]@{
                    Date       = [DateTime]$Matches[1]
                    Attributes = $Matches[2]
                    Size       = [int64]$Matches[3]
                    Compressed = [int64]$Matches[4]
                    Path       = $Matches[5].Trim()
                }
            }
        }

        $Result = [PSCustomObject]@{
            ArchiveName = $($RoadshowPath.FullName)
            SourcePath = $ParsedFiles.where({$_.Path -match "Workbench\\Libs\\020\\bsdsocket\.library"}).path 
        }
        
        return $result

    }