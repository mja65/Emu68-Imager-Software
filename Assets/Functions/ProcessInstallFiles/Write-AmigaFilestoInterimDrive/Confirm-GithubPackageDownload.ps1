function Confirm-GithubPackageDownload {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DownloadPath,

        [string]$ExpectedHash,

        [string]$BackupSourceLocation,

        [string]$FallbackExpectedHash
    )

    $ExpectedHash = $ExpectedHash -replace '^sha256:', ''

    if ((Test-Path -LiteralPath $DownloadPath -PathType Leaf) -and
        ([string]::IsNullOrWhiteSpace($ExpectedHash) -or
         (Compare-FileHash -FiletoCheck $DownloadPath -HashtoCheck $ExpectedHash))) {
        return $true
    }

    if (Test-Path -LiteralPath $DownloadPath -PathType Leaf) {
        Write-InformationMessage -Message "Hash verification failed for downloaded package $DownloadPath"
        Remove-Item -LiteralPath $DownloadPath -Force
    }

    if ([string]::IsNullOrWhiteSpace($BackupSourceLocation)) {
        return $false
    }

    $BackupPath = $BackupSourceLocation
    if (-not [System.IO.Path]::IsPathRooted($BackupPath)) {
        $BackupPath = Join-Path $Script:Settings.LocationofAmigaFiles $BackupPath
    }
    $BackupPath = [System.IO.Path]::GetFullPath($BackupPath)

    if (-not (Test-Path -LiteralPath $BackupPath -PathType Leaf)) {
        Write-InformationMessage -Message "Pinned fallback package is unavailable: $BackupPath"
        return $false
    }

    Copy-Item -LiteralPath $BackupPath -Destination $DownloadPath -Force

    if ([string]::IsNullOrWhiteSpace($FallbackExpectedHash)) {
        $FallbackExpectedHash = $ExpectedHash
    }
    $FallbackExpectedHash = $FallbackExpectedHash -replace '^sha256:', ''

    if (-not [string]::IsNullOrWhiteSpace($FallbackExpectedHash) -and
        -not (Compare-FileHash -FiletoCheck $DownloadPath -HashtoCheck $FallbackExpectedHash)) {
        Write-InformationMessage -Message "Hash verification failed for pinned fallback package $BackupPath"
        Remove-Item -LiteralPath $DownloadPath -Force
        return $false
    }

    Write-InformationMessage -Message "Using verified pinned fallback package $BackupPath"
    return $true
}
