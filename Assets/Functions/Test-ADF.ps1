function Test-ADF {
    <#
    .SYNOPSIS
        Tests if a file is a valid Amiga Disk File (.adf) image.

    .DESCRIPTION
        Validates file size (typically 901,120 bytes for standard DD floppies or multiple of 512)
        and verifies the DOS boot block and root block integrity. Returns $true or $false.

    .PARAMETER Path
        Path to the file to test.

    .PARAMETER Quiet
        Suppresses warning output on invalid disks.

    .EXAMPLE
        if (Test-AmigaDiskFile -Path "disk.adf") {
            Expand-AmigaDiskFile -Path "disk.adf" -DestinationPath ".\Extracted"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Path = "",

        [Parameter(Mandatory = $false)]
        [switch]$Quiet
    )

    process {
        if ([string]::IsNullOrWhiteSpace($Path)) {
            if (-not $Quiet) { Write-Warning "Path is empty." }
            return $false
        }

        $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
            if (-not $Quiet) { Write-Warning ("File not found: '{0}'" -f $Path) }
            return $false
        }

        try {
            $engine = New-Object AmigaAdf.UnAdfEngine
            $engine.Load($resolved, [char]'_')
            return ($engine.DiskInfo -ne $null -and $engine.DiskInfo.TotalBlocks -gt 0)
        }
        catch {
            if (-not $Quiet) { Write-Warning ("Failed to parse ADF file '{0}': {1}" -f $Path, $_.Exception.Message) }
            return $false
        }
    }
}