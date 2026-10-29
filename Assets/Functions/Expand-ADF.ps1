function Expand-ADF {
    <#
    .SYNOPSIS
        Extracts all or specific files and directories from an Amiga Disk File (.adf).

    .DESCRIPTION
        Extracts files from an Amiga Disk File archive. Automatically creates directories,
        preserves Amiga timestamps, and cleanses invalid Windows characters (\ / : * ? " < > |),
        control codes (<32), reserved device names (CON, PRN, AUX, etc.), and Amiga extended
        Latin-1 characters (such as ñ, é, ä, ö, ü) using the configurable -ReplaceChar character.

    .PARAMETER Path
        Path to the .adf disk image. Accepts pipeline input by value or property name.

    .PARAMETER DestinationPath
        Directory where files will be extracted. Default is ".\Extracted".

    .PARAMETER Filter
        Optional wildcard or text filter (e.g. "*.txt", "Help*", "Startup-Sequence").

    .PARAMETER Include
        Optional array of specific file paths or names to extract.

    .PARAMETER ReplaceChar
        Character to replace invalid Windows characters and Amiga special characters with. Default is '_'.

    .PARAMETER PassThru
        When specified, returns System.IO.FileInfo objects of all extracted files into the pipeline.

    .PARAMETER Force
        Overwrites existing files without prompting.

    .PARAMETER Quiet
        Suppresses console progress messages.

    .PARAMETER InputObject
        Piped AmigaAdf.DiskEntry objects from Get-AmigaDiskFileItem to extract specific files.

    .EXAMPLE
        # Extract all files from an ADF to a folder
        Expand-AmigaDiskFile -Path "workbench.adf" -DestinationPath "C:\Extracted\Workbench"

    .EXAMPLE
        # Extract only specific files using a filter
        Expand-AmigaDiskFile -Path "workbench.adf" -DestinationPath ".\Docs" -Filter "*.guide"

    .EXAMPLE
        # Extract specific files using -Include
        Expand-AmigaDiskFile -Path "workbench.adf" -DestinationPath ".\Extracted" -Include @("S/Startup-Sequence", "Devs/system-configuration")

    .EXAMPLE
        # Query files with Get-AmigaDiskFileItem, filter by size, and extract via pipeline
        Get-AmigaDiskFileItem -Path "games.adf" -Recurse | Where-Object { $_.Length -gt 10000 } | Expand-AmigaDiskFile -DestinationPath ".\BigFiles"

    .EXAMPLE
        # Extract and pass FileInfo objects to the next step in a bigger program
        $extractedFiles = Expand-AmigaDiskFile -Path "workbench.adf" -DestinationPath ".\Out" -PassThru
    #>
    [CmdletBinding(DefaultParameterSetName = 'PathSet')]
    param(
        [Parameter(ParameterSetName = 'PathSet', Position = 0, Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName', 'File', 'FilePath')]
        [string]$Path = "",

        [Parameter(Position = 1, Mandatory = $false)]
        [Alias('Destination', 'OutDir', 'd')]
        [string]$DestinationPath = ".\Extracted",

        [Parameter(Mandatory = $false)]
        [Alias('ReplaceWith', 'w')]
        [string]$ReplaceChar = "_",

        [Parameter(Mandatory = $false)]
        [Alias('f')]
        [string]$Filter = "",

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @(),

        [Parameter(Mandatory = $false)]
        [switch]$PassThru,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$Quiet,

        [Parameter(ParameterSetName = 'PipelineSet', Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]$InputObject
    )

    begin {
        $extractedList = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    }

    process {
        # --- Handle Pipeline InputObject from Get-AmigaDiskFileItem ---
        if ($PSCmdlet.ParameterSetName -eq 'PipelineSet' -and $InputObject) {
            $entry = $null
            $diskPath = $null

            if ($InputObject.PSObject.Properties['AdfEntry']) {
                $entry = $InputObject.AdfEntry
                $diskPath = $InputObject.DiskPath
            } elseif ($InputObject -is [AmigaAdf.AdfEntry]) {
                $entry = $InputObject
            }

            if ($entry -and -not $entry.IsDirectory) {
                if (-not $diskPath -and [string]::IsNullOrWhiteSpace($Path)) {
                    Write-Error "Cannot extract entry without knowing parent ADF path."
                    return
                }
                $effectivePath = if ($diskPath) { $diskPath } else { $Path }
                $resolvedAdf = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($effectivePath)
                $destResolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)

                $char = [char]'_'
                if (-not [string]::IsNullOrEmpty($ReplaceChar)) { $char = $ReplaceChar[0] }

                $engine = New-Object AmigaAdf.UnAdfEngine
                $engine.Load($resolvedAdf, $char)

                $outPath = $engine.ExtractEntry($entry, $destResolved)
                if ($outPath -and (Test-Path -LiteralPath $outPath)) {
                    $fi = New-Object System.IO.FileInfo($outPath)
                    $extractedList.Add($fi)
                    if (-not $Quiet) {
                        Write-Host ("Extracted: {0} -> {1}" -f $entry.AmigaPath, $outPath)
                    }
                }
                return
            }
        }

        # --- Standard Path Parameter Set ---
        if ([string]::IsNullOrWhiteSpace($Path)) {
            Write-Error "Please specify the path to an Amiga Disk File (.adf) using -Path."
            return
        }

        $resolvedAdf = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        if (-not (Test-Path -LiteralPath $resolvedAdf -PathType Leaf)) {
            Write-Error ("ADF disk file not found: '{0}'" -f $Path)
            return
        }

        $destResolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)
        if (-not (Test-Path -LiteralPath $destResolved)) {
            $null = New-Item -ItemType Directory -Path $destResolved -Force
        }

        $char = [char]'_'
        if (-not [string]::IsNullOrEmpty($ReplaceChar)) { $char = $ReplaceChar[0] }

        $engine = New-Object AmigaAdf.UnAdfEngine
        $engine.Load($resolvedAdf, $char)

        # Handle specific -Include list if provided
        if ($Include -and $Include.Count -gt 0) {
            $allEntries = $engine.GetAllEntries($false)
            $extractedCount = 0

            foreach ($item in $allEntries) {
                $shouldExtract = $false
                foreach ($inc in $Include) {
                    if ($item.Name -like "*$inc*" -or $item.AmigaPath -like "*$inc*" -or $item.RelativeWindowsPath -like "*$inc*") {
                        $shouldExtract = $true
                        break
                    }
                }

                if ($shouldExtract) {
                    $outPath = $engine.ExtractEntry($item, $destResolved)
                    if ($outPath -and (Test-Path -LiteralPath $outPath)) {
                        $extractedCount++
                        $fi = New-Object System.IO.FileInfo($outPath)
                        $extractedList.Add($fi)
                        if (-not $Quiet) {
                            Write-Host ("Extracted: {0} -> {1}" -f $item.AmigaPath, $outPath)
                        }
                    }
                }
            }

            if (-not $Quiet) {
                Write-Host ("Extraction complete: {0} file(s) extracted from '{1}' to '{2}'." -f $extractedCount, (Split-Path $resolvedAdf -Leaf), $destResolved) -ForegroundColor Green
            }
        }
        else {
            # Standard ExtractAll with optional Filter
            $opt = New-Object AmigaAdf.UnAdfOptions
            $opt.Extract = $true
            $opt.DestinationDir = $destResolved
            $opt.WildcardReplaceChar = $char
            $opt.Filter = $Filter
            $opt.Verbosity = if ($Quiet) { 0 } else { 1 }

            $logCallback = $null
            if (-not $Quiet) {
                $logCallback = [System.Action[string]]{
                    param([string]$msg)
                    Write-Host "  $msg"
                }
            }

            $count = $engine.ExtractAll($opt, $logCallback)

            if (-not $Quiet) {
                Write-Host ("Extraction complete: {0} file(s) extracted from '{1}' to '{2}'." -f $count, (Split-Path $resolvedAdf -Leaf), $destResolved) -ForegroundColor Green
            }

            if ($PassThru) {
                $found = Get-ChildItem -LiteralPath $destResolved -Recurse -File -ErrorAction SilentlyContinue
                if ($found) {
                    foreach ($f in $found) {
                        $extractedList.Add($f)
                    }
                }
            }
        }
    }

    end {
        if ($PassThru) {
            return $extractedList
        }
    }
}