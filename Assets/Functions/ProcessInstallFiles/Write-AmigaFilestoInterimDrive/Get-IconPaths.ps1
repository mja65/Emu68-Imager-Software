Function Get-IconPaths {
    param (

    )
   
    $IconLocationDetailsCSV = Get-InputCSVs -IconSets | Where-Object {$_.IconsetName -eq $Script:GUIActions.SelectedIconSet} 
    
    $IconTypes = @(
        "NewFolder", 
        "SystemDisk", 
        "WorkDisk", 
        "Emu68BootDisk"
    )
    
    $IconLocationDetailsToReturn = $null

    $IconLocationDetailsToReturn = $IconTypes | ForEach-Object {
        $IconType = $_
        
        # Define the custom properties dynamically
        [PSCustomObject]@{
            IconType       = $IconType
            Source         = $IconLocationDetailsCSV."$($IconType)IconSource"
            SourceLocation = $IconLocationDetailsCSV."$($IconType)IconSourceLocation"
            InstallMedia   = $IconLocationDetailsCSV."$($IconType)IconInstallMedia"
            FilestoInstall = ($IconLocationDetailsCSV."$($IconType)IconFilestoInstall").Replace('/','\')
            ModifyInfoFileType = ($IconLocationDetailsCSV."$($IconType)IconModifyInfoFileType")
            NewFileNameFlag = [bool]$null
            InstallMediaPath = $null
            NewFileName = $null
        }
    }
    
    $HashTableforInstallMedia = @{} # Clear Hash
    $Script:GUIActions.FoundInstallMediatoUse | ForEach-Object {
        $HashTableforInstallMedia[$_.ADF_Name] = @($_.Path) 
    }

    $IconLocationDetailsToReturn | ForEach-Object {
         if ($HashTableforInstallMedia.ContainsKey($_.Source)){
            $_.InstallMediaPath = $HashTableforInstallMedia.($_.Source)[0]
         }
        if ($_.IconType -match 'Disk'){
            if ((Split-Path -Path $_.FilestoInstall -Leaf) -ne 'disk.info'){
                $_.NewFileNameFlag = $true 
                $_.NewFileName = "disk.info"
            }
            else {
                $_.NewFileNameFlag = $false
            }
        }
        elseif ($_.IconType -match 'NewFolder'){
            $_.NewFileNameFlag = $true
            $_.NewFileName = "Newfolder.info"
        }
    }
    
    return $IconLocationDetailsToReturn


}
