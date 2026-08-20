function Test-PackageArchiveStructure {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,

        [string]$RequiredArchiveEntries
    )

    if ([string]::IsNullOrWhiteSpace($RequiredArchiveEntries)) {
        return $true
    }

    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
        Write-InformationMessage -Message "Package archive is unavailable for structure validation: $ArchivePath"
        return $false
    }

    $SevenZipPath = $Script:ExternalProgramSettings.SevenZipFilePath
    if (-not (Test-Path -LiteralPath $SevenZipPath -PathType Leaf)) {
        Write-InformationMessage -Message "7-Zip is unavailable for package structure validation: $SevenZipPath"
        return $false
    }

    $ArchiveListing = & $SevenZipPath 'l' '-slt' $ArchivePath 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-InformationMessage -Message "Unable to read package archive structure: $ArchivePath"
        return $false
    }

    $ArchiveEntries = @(
        $ArchiveListing |
            ForEach-Object { "$_" } |
            Where-Object { $_ -match '^Path = (.+)$' } |
            ForEach-Object { $Matches[1] -replace '/', '\' }
    )

    foreach ($RequiredEntry in ($RequiredArchiveEntries -split '\|' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
        $RequiredEntry = $RequiredEntry.Trim() -replace '/', '\'
        $EntryFound = $ArchiveEntries | Where-Object { $_ -like $RequiredEntry } | Select-Object -First 1
        if (-not $EntryFound) {
            Write-InformationMessage -Message "Required archive entry is missing from $ArchivePath`: $RequiredEntry"
            return $false
        }
    }

    return $true
}
