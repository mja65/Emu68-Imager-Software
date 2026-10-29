function Get-ADFItem {
    <#
    .SYNOPSIS
        Lists files and directories inside an Amiga Disk File (.adf) as PowerShell objects.

    .DESCRIPTION
        Parses the ADF filesystem structure and outputs rich custom PowerShell objects
        for each file and directory, containing Name, WindowsName (cleansed), AmigaPath,
        RelativePath, Length (bytes), LastWriteTime, Protection string, Comment, and
        the underlying .NET AdfEntry object for pipeline chaining.

    .PARAMETER Path
        Path to the .adf disk image. Accepts pipeline input.

    .PARAMETER Recurse
        When specified, recursively traverses all subdirectories. Otherwise lists root items only.

    .PARAMETER Filter
        Optional filter pattern to match against Amiga filenames or paths.

    .PARAMETER ReplaceChar
        Character used to sanitize Windows filenames. Default is '_'.

    .EXAMPLE
        Get-AmigaDiskFileItem -Path "workbench.adf" -Recurse

    .EXAMPLE
        # Filter files larger than 10 KB and sort by size descending
        Get-AmigaDiskFileItem -Path "workbench.adf" -Recurse | Where-Object { $_.Length -gt 10240 } | Sort-Object -Property Length -Descending | Format-Table Name, Length, LastWriteTime

    .EXAMPLE
        # Pipe matching items directly to Expand-AmigaDiskFile
        Get-AmigaDiskFileItem -Path "workbench.adf" -Recurse -Filter "*.info" | Expand-AmigaDiskFile -DestinationPath ".\Icons"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName', 'File', 'FilePath')]
        [string]$Path = "",

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [string]$Filter = "",

        [Parameter(Mandatory = $false)]
        [string]$ReplaceChar = "_"
    )

    process {
        if ([string]::IsNullOrWhiteSpace($Path)) {
            Write-Error "Please specify the path to an Amiga Disk File (.adf) using -Path."
            return
        }

        $resolvedAdf = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        if (-not (Test-Path -LiteralPath $resolvedAdf -PathType Leaf)) {
            Write-Error ("ADF disk file not found: '{0}'" -f $Path)
            return
        }

        $char = [char]'_'
        if (-not [string]::IsNullOrEmpty($ReplaceChar)) { $char = $ReplaceChar[0] }

        $engine = New-Object AmigaAdf.UnAdfEngine
        $engine.Load($resolvedAdf, $char)

        $entries = if ($Recurse) {
            $engine.GetAllEntries($true)
        } else {
            $engine.RootDirectory.Children
        }

        if (-not [string]::IsNullOrEmpty($Filter)) {
            $entries = $entries | Where-Object {
                $_.Name -like "*$Filter*" -or $_.AmigaPath -like "*$Filter*" -or $_.RelativeWindowsPath -like "*$Filter*"
            }
        }

        foreach ($item in $entries) {
            $modePrefix = "-"
            if ($item.IsDirectory) { $modePrefix = "d" }
            $modeStr = $modePrefix + $item.ProtectionString

            [PSCustomObject]@{
                PSTypeName     = 'AmigaAdf.DiskEntry'
                Name           = $item.Name
                WindowsName    = $item.SanitizedName
                AmigaPath      = $item.AmigaPath
                RelativePath   = $item.RelativeWindowsPath
                IsDirectory    = $item.IsDirectory
                Length         = $item.Size
                LastWriteTime  = $item.Timestamp
                Mode           = $modeStr
                Protection     = $item.ProtectionString
                ProtectionBits = $item.ProtectionBits
                Comment        = $item.Comment
                HeaderBlock    = $item.HeaderBlock
                AdfEntry       = $item
                DiskPath       = $resolvedAdf
            }
        }
    }
}