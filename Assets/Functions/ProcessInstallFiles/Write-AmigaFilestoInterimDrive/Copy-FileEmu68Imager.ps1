Function Copy-FileEmu68Imager {
    param(
        $SourcePath,
        $DestinationPath
    )

    try {
            [System.IO.File]::Copy($SourcePath, $DestinationPath, $true)
        }
        catch [System.UnauthorizedAccessException] {
            if ([System.IO.File]::Exists($DestinationPath)) {
                [System.IO.File]::SetAttributes($DestinationPath, [System.IO.FileAttributes]::Normal)
                [System.IO.File]::Copy($SourcePath, $DestinationPath, $true)
            }
            else {
                throw $_
            }
        }
        catch {
            throw $_
        }

}