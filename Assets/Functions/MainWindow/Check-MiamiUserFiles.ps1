function Check-MiamiUserFiles {
        param (
            $MiamiFilesPath

        )

        # $MiamiFilesPath = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\UserFiles\ExistingApplications"

        #$DestinationPath = "\disk6"
        $FilestoCopy= [System.Collections.Generic.List[PSCustomObject]]::New()

        $ListofFilestoFind = @(
            [PSCustomObject]@{Name="MIAMI.KEY1"; SizeBytes=2048}
            [PSCustomObject]@{Name="MIAMI.KEY2"; SizeBytes=2048}
            [PSCustomObject]@{Name="MIAMIDX.KEY"; SizeBytes=4096}

        )
                
        $UserFiles = Get-ChildItem -Path $MiamiFilesPath -File -Recurse -ErrorAction SilentlyContinue

        foreach ($Item in $ListofFilestoFind) {
            $Match = $UserFiles | Where-Object { $_.Name -eq $Item.Name -and $_.Length -eq $Item.SizeBytes } | Select-Object -First 1
            if ($Match) {
                $FilestoCopy += [PSCustomObject]@{
                    SourcePath = $($Match.FullName)
                    DestinationPath = "\Programs\Miami"
                }
            }
        }   

        if ($FilestoCopy.Count -eq $ListofFilestoFind.Count) {
            return ((split-path $FilestoCopy.SourcePath -parent) | Select-Object $_ -Unique)
        }
        else {
            return $false
        }
    }   
    