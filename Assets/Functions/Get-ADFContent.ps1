function Get-ADFContent {
    <#
    .SYNOPSIS
        Reads the content of a file inside an Amiga Disk File directly into memory.

    .DESCRIPTION
        Extracts file contents into a byte array [byte[]] or decoded text string without
        saving to disk. Ideal for inspect-before-extract workflows or automated parsing.

    .PARAMETER Path
        Path to the .adf disk image.

    .PARAMETER FilePath
        Relative path or filename of the file inside the ADF (e.g. "S/Startup-Sequence").

    .PARAMETER AsText
        When specified, decodes the raw bytes into a string using the specified encoding.

    .PARAMETER Encoding
        Encoding to decode text with. Default is ISO-8859-1 (Amiga Latin-1).

    .EXAMPLE
        # Read text file directly into a variable
        $startup = Get-AmigaDiskFileContent -Path "workbench.adf" -FilePath "S/Startup-Sequence" -AsText

    .EXAMPLE
        # Read raw binary bytes
        $bytes = Get-AmigaDiskFileContent -Path "workbench.adf" -FilePath "C/Dir"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName', 'File')]
        [string]$Path = "",

        [Parameter(Position = 1, Mandatory = $false)]
        [Alias('FileInAdf', 'ItemPath')]
        [string]$FilePath = "",

        [Parameter(Mandatory = $false)]
        [switch]$AsText,

        [Parameter(Mandatory = $false)]
        [string]$Encoding = "ISO-8859-1"
    )

    process {
        if ([string]::IsNullOrWhiteSpace($Path)) {
            Write-Error "Please specify the path to an Amiga Disk File (.adf) using -Path."
            return
        }
        if ([string]::IsNullOrWhiteSpace($FilePath)) {
            Write-Error "Please specify the file path inside the ADF using -FilePath."
            return
        }

        $resolvedAdf = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        if (-not (Test-Path -LiteralPath $resolvedAdf -PathType Leaf)) {
            Write-Error ("ADF disk file not found: '{0}'" -f $Path)
            return
        }

        $engine = New-Object AmigaAdf.UnAdfEngine
        $engine.Load($resolvedAdf, [char]'_')

        $bytes = $engine.ReadFileContentByPath($FilePath)
        if (-not $bytes -or $bytes.Length -eq 0) {
            # Fallback search through all entries
            $all = $engine.GetAllEntries($false)
            $match = $all | Where-Object { $_.Name -eq $FilePath -or $_.AmigaPath -like "*$FilePath*" -or $_.RelativeWindowsPath -like "*$FilePath*" } | Select-Object -First 1
            if ($match) {
                $bytes = $engine.ReadFileContent($match)
            }
        }

        if (-not $bytes -or $bytes.Length -eq 0) {
            Write-Error ("File '{0}' not found or empty inside '{1}'." -f $FilePath, (Split-Path $resolvedAdf -Leaf))
            return
        }

        if ($AsText) {
            $enc = [System.Text.Encoding]::GetEncoding($Encoding)
            return $enc.GetString($bytes)
        } else {
            return $bytes
        }
    }
}