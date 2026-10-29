function Get-CustomAmigaKickstartScript {
    param (
        $KickstartRom   
    )

    # $KickstartRom = $Script:GUIActions.FoundKickstarttoUse.where({ $_.KickstartVersion })

    $OutputFile = [System.IO.Path]::GetFileNameWithoutExtension($KickstartRom.Fat32Name)

    $InputRomPath = $KickstartRom.KickstartPath

    $KickstartBanks = @(
        [PSCustomObject]@{ Address = "0xF80000"; SizeKiloBytes = 512; Sequence = 1 }
        [PSCustomObject]@{ Address = "0xA80000"; SizeKiloBytes = 1024; Sequence = 2 }
        [PSCustomObject]@{ Address = "0xE00000"; SizeKiloBytes = 512; Sequence = 3 }
    )

    $KickstartComponents = Get-InputFileCSV -CSV "KickstartComponents" | Sort-Object -Property Chunk, @{ Expression = { [int]$_.ChunkSequence } }
   
    $CapitolinePath = [System.IO.Path]::GetFullPath($Script:ExternalProgramSettings.CapCLIPath)

    $Header = "var SOURCEROM `"$InputRomPath`""

    $Counter = 0
    
    $Script = @(
        Foreach ($Bank in $KickstartBanks){
            $ComponentsforBank = $KickstartComponents.Where({ $Bank.Address -eq $_.Chunk })
            "rom $Counter"
            "newrom $($Bank.SizeKiloBytes)k" 
            Foreach ($ComponentinBank in $ComponentsforBank){
                If ($ComponentinBank.ComponentType -eq "Capitoline"){
                    "add `"$CapitolinePath\Components\BinaryChunks\$($ComponentinBank.Component)`""
                    if ($ComponentinBank.Component -like "*scantable*"){
                        "var ENDSKIP romdata `$exec.library.(ROMTAG.ENDSKIP) 4"
                        "var ENDSKIP mid 2"
                        "patch `$$($ComponentinBank.Component).(START) 0x00F80000`$ENDSKIP"
                        "var STSTART `$$($ComponentinBank.Component).(START)"
                        "var STSTART add `$ROMBASE"
                        "find `$exec.library 0x00F80000`$ENDSKIP00F800000100000000F0000000F80000FFFFFFFF"
                        "var FIND add `$ROMBASE"
                        "find `$exec.library `$FIND"
                        "patch `$FIND `$STSTART"
                    }
                }
                elseif ($ComponentinBank.ComponentType -eq "Kickstart"){
                    "add `"`$SOURCEROM`" $($ComponentinBank.Component)" 
                }
                elseif ($ComponentinBank.ComponentType -eq "File"){
                    $ExtractedFileFolder = [System.IO.Path]::GetFileNameWithoutExtension($ComponentinBank.SourceLocation) 
                    $BaseFolder = Join-PathMulti $Script:Settings.WebPackagesDownloadLocation $ExtractedFileFolder -UseFullPath
                    $SourcePathToUse = if ([string]::IsNullOrWhiteSpace($ComponentinBank.SourcePathMangled)) { $ComponentinBank.SourcePath } else { $ComponentinBank.SourcePathMangled }
                    if ($SourcePathToUse.Contains('*')) {
                        $PathtoResolve = join-path $BaseFolder $SourcePathToUse
                        $FullSourcePath  = (Get-ChildItem -Path $PathtoResolve -ErrorAction Stop | Select-Object -First 1).FullName
                    }
                    else {
                        $FullSourcePath = join-path $BaseFolder $SourcePathToUse
                    }
                    "add `"$FullSourcePath`""
                }
            }
            
            "add checksum"
            "add size"
            "add vectors"
            "checksum"        
            $Counter ++
        }
        "romprofile single 0 1 2"
        "saveprofile rom `"$($Script:GUIActions.CustomKickstartROMPath)`""
        "exit"
    )

return $Script

}