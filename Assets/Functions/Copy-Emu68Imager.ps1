Function Copy-Emu68Imager {
    Param (
        [switch]$UserFiles,
        [Switch]$Compress,
        $NewLocation
    )
    
   # $NewLocation = "E:\Emu 68 Imager Test Files"    
   
    If (test-path $NewLocation){
        $null = remove-item -path $NewLocation -recurse -force
    }

    $null = New-Item -Path $NewLocation -ItemType Directory -Force
    
    if (Test-path (join-path $NewLocation "Assets") -PathType Container){
        $null = remove-item -path (join-path $NewLocation "Assets") -recurse -force
    }
    
    $FilesToCopy = @(
        ".\Assets",
        ".\Script",
        ".\Emu68Imager.cmd",
        ".\readme.md",
        ".\LICENSE",
        ".\Programs\7z\7z.dll",
        ".\Programs\7z\7z.exe",
        ".\Programs\7z\\7zLicense",
        ".\Programs\Lhasa\lha.exe",
        ".\Programs\Lhasa\Copying.txt"
        ".\Programs\Lhasa\lha.html"
        ".\Programs\Lhasa\News.txt"
        ".\Programs\Lhasa\Readme.txt"
        ".\Programs\UnLzx\unlzx.exe"
        ".\Programs\UnLzx\W95unlzx.readme"
        ".\Programs\UnADF\bin"
        ".\Programs\UnADF\AUTHORS"
        ".\Programs\UnADF\ChangeLog"
        ".\Programs\UnADF\COPYING"
        ".\Programs\UnADF\COPYING-GPL2"
        ".\Programs\UnADF\README.md"
        ".\Programs\UnADF\bin\adf.dll"
        ".\Programs\UnADF\bin\adf.exp"
        ".\Programs\UnADF\bin\adf.lib"
        ".\Programs\UnADF\bin\adfbitmap.exe"
        ".\Programs\UnADF\bin\adfformat.exe"
        ".\Programs\UnADF\bin\adfimgcreate.exe"
        ".\Programs\UnADF\bin\adfinfo.exe"
        ".\Programs\UnADF\bin\adfls.exe"
        ".\Programs\UnADF\bin\adfsalvage.exe"
        ".\Programs\UnADF\bin\unadf.exe"
    )
        


    foreach ($File in $FilesToCopy) {
        $RelativePath = Split-Path $File -NoQualifier
        $DestinationPath = Join-Path $NewLocation $RelativePath
        $TargetFolder = Split-Path $DestinationPath -Parent
        if (-not (Test-Path $TargetFolder)) {
            $null = New-Item -Path $TargetFolder -ItemType Directory -Force
        }
        Copy-Item -Path $File -Destination $DestinationPath -Recurse -Force
    }


    
    If ($UserFiles){
        $UserFilesTarget = Join-Path $NewLocation "UserFiles"
        if (-not (Test-Path $UserFilesTarget)) {        
            $null = New-Item -Path $UserFilesTarget -ItemType Directory -Force
        }
        Get-ChildItem -Path ".\UserFiles" | Where-Object { $_.Name -ne "SavedOutputImages" } | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $UserFilesTarget -Recurse -Force
        }
    }

    If ($Compress){
        $ZipPath = "$NewLocation.zip"
        if (Test-Path $ZipPath) {
            $null = Remove-Item -Path $ZipPath -Force
        }
        Compress-Archive -Path "$NewLocation\*" -DestinationPath $ZipPath -Force        
    }

}
