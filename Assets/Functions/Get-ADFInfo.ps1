function Get-ADFInfo {
    <#
    .SYNOPSIS
        Inspects an Amiga Disk File (.adf) and returns volume and filesystem metadata.

    .DESCRIPTION
        Returns a rich PowerShell object containing DiskName, DOS Type (OFS, FFS, INTL, DIRCACHE),
        block counts, root block ID, creation and alteration timestamps, total file/dir counts,
        and total data bytes.

    .PARAMETER Path
        Path to the .adf disk image. Accepts pipeline input.

    .PARAMETER ReplaceChar
        Character used to sanitize disk name for Windows. Default is '_'.

    .EXAMPLE
        Get-AmigaDiskFileInfo -Path "workbench.adf"

    .EXAMPLE
        Get-ChildItem *.adf | Get-AmigaDiskFileInfo | Format-Table DiskName, DosTypeString, TotalFiles, TotalDataBytes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName', 'File')]
        [string]$Path = "",

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
        $info = $engine.DiskInfo

        [PSCustomObject]@{
            PSTypeName        = 'AmigaAdf.DiskInfo'
            Path              = $resolvedAdf
            DiskName          = $info.DiskName
            SanitizedDiskName = $info.SanitizedDiskName
            DosType           = $info.DosType.ToString()
            DosTypeString     = $info.DosTypeString
            IsFFS             = $info.IsFFS
            IsInternational   = $info.IsInternational
            IsDirCache        = $info.IsDirCache
            BlockSize         = $info.BlockSize
            TotalBlocks       = $info.TotalBlocks
            TotalSizeBytes    = $info.TotalSizeBytes
            RootBlockNumber   = $info.RootBlockNumber
            CreationDate      = $info.CreationDate
            AlterationDate    = $info.AlterationDate
            TotalFiles        = $info.TotalFiles
            TotalDirectories  = $info.TotalDirectories
            TotalDataBytes    = $info.TotalDataBytes
        }
    }
}