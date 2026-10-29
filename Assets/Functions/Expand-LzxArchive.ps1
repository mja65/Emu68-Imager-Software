function Expand-LzxArchive {
    param(
        [string]$Path,
        [string]$DestinationPath,
        [string]$InvalidCharReplacement = '_',
        [switch]$Force,
        [switch]$Quiet
    )

    #$Path = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\WebPackagesDownload\DOpus417pre21.lzx"
    #$DestinationPath = "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\Powershell"

    if (-not (Test-Path $DestinationPath -PathType Container)){
        $null = [System.IO.Directory]::CreateDirectory($DestinationPath) 
    }

    $results = [AmigaLzx.LzxEngine]::Extract($Path, $DestinationPath, $InvalidCharReplacement, [bool]$Force)
    $results | ForEach-Object {
        if (-not ($_.CrcMatches)){
            return $false
        }
    }

    return $true

}
