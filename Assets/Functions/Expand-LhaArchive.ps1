function Expand-LhaArchive {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias('unlha')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Alias('FullName', 'LiteralPath')]
        [string]$Path,

        [Parameter(Position = 1)]
        [string]$DestinationPath,

        [Parameter()]
        [char]$ReplaceChar = '_',

        [Parameter()]
        [Alias('PreserveAccents', 'UnicodeFilenames', 'MapIso8859', 'Unicode')]
        [switch]$ConvertUnicode,

        [Parameter()]
        [Alias('Silent')]
        [switch]$Quiet,

        [Parameter()]
        [Alias('NoProg', 'HideProgress')]
        [switch]$NoProgress,

        [Parameter()]
        [switch]$SkipCrcCheck,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$PassThru
    )

    process {
        $origOutputEncoding = [Console]::OutputEncoding
        $origProgressPref = $ProgressPreference
        try {
            [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
            $OutputEncoding = [System.Text.Encoding]::UTF8
        } catch { }

        if ($Quiet -or $NoProgress) {
            $ProgressPreference = 'SilentlyContinue'
        }

        try {
            $resolvedPaths = @()
            try {
                $resolvedPaths = Resolve-Path -LiteralPath $Path -ErrorAction Stop | ForEach-Object { $_.Path }
            } catch {
                try {
                    $resolvedPaths = Resolve-Path -Path $Path -ErrorAction Stop | ForEach-Object { $_.Path }
                } catch {
                    Write-Error "LHA Archive file not found: $Path"
                    return
                }
            }

            foreach ($resolved in $resolvedPaths) {
                $targetDest = $DestinationPath
                if (-not $targetDest) {
                    $targetDest = [System.IO.Path]::Combine((Split-Path $resolved -Parent), [System.IO.Path]::GetFileNameWithoutExtension($resolved))
                }

                if (-not (Test-Path -LiteralPath $targetDest)) {
                    [System.IO.Directory]::CreateDirectory($targetDest) | Out-Null
                }

                Write-Verbose "Reading LHA headers from: $resolved"
                $entries = [AmigaLha.LhaEngine]::ReadHeaders($resolved, $ReplaceChar, $ConvertUnicode.IsPresent)
                Write-Verbose "Found $($entries.Count) items in archive."

                if ($entries.Count -eq 0) {
                    if (-not $Quiet) {
                        Write-Warning "No valid LHA entries found in: $resolved"
                    }
                    continue
                }

                $verifyCrc = -not $SkipCrcCheck
                $extractedCount = 0
                $totalEntries = $entries.Count
                $progressWatch = [System.Diagnostics.Stopwatch]::StartNew()
                $leafArchive = Split-Path $resolved -Leaf

                for ($i = 0; $i -lt $totalEntries; $i++) {
                    $entry = $entries[$i]
                    $targetFile = [System.IO.Path]::Combine($targetDest, $entry.CleansedPath)

                    if ($entry.OriginalPath -ne $entry.CleansedPath) {
                        Write-Verbose "Amiga Path Processed: '$($entry.OriginalPath)' -> '$($entry.CleansedPath)'"
                    }

                    if (-not $Quiet -and -not $NoProgress) {
                        if ($progressWatch.ElapsedMilliseconds -gt 150 -or $i -eq ($totalEntries - 1)) {
                            $displayFile = $entry.CleansedPath
                            # Strip control characters from progress bar status to prevent terminal corruption
                            $displayFile = [System.Text.RegularExpressions.Regex]::Replace($displayFile, '[p{C}]', '')
                            # Prevent console line-wrapping buffer overflow which causes screen garbage
                            if ($displayFile.Length -gt 50) {
                                $displayFile = '...' + $displayFile.Substring($displayFile.Length - 47)
                            }
                            Write-Progress -Activity "Extracting $leafArchive" -Status "[$($i+1)/$totalEntries] $displayFile" -PercentComplete ([int](($i / $totalEntries) * 100))
                            $progressWatch.Restart()
                        }
                    }

                    if ($PSCmdlet.ShouldProcess($targetFile, "Extract $($entry.Method) ($($entry.OriginalSize) bytes)")) {
                        $result = [AmigaLha.LhaEngine]::ExtractEntry($resolved, $entry, $targetDest, $verifyCrc)

                        if ($result.Success) {
                            $extractedCount++
                            if ($PassThru) {
                                Get-Item -LiteralPath $result.OutputFilePath
                            }
                        } else {
                            $safeName = [System.Text.RegularExpressions.Regex]::Replace($entry.CleansedPath, '[p{C}]', '_')
                            Write-Warning "Failed extracting '$safeName': $($result.ErrorMessage)"
                        }
                    }
                }

                if (-not $Quiet -and -not $NoProgress) {
                    Write-Progress -Activity "Extracting $leafArchive" -Completed
                }

                if (-not $Quiet) {
                    Write-Host "Extracted $extractedCount files into: $targetDest" -ForegroundColor Green
                }
            }
        } finally {
            $ProgressPreference = $origProgressPref
            try { [Console]::OutputEncoding = $origOutputEncoding } catch { }
        }
    }
}