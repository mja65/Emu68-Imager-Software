function Test-ZipPassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Password = "",

        [Parameter(Mandatory = $false)]
        [switch]$Quiet
    )

    process {
        try {
            $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
            if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
                if ($Quiet) { return $false }
                Write-Error "ZIP file not found at: $resolvedPath"
                return $null
            }

            $result = [PowerShellZip.ZipDecryptor]::TestArchive($resolvedPath, $Password)

            if ($Quiet) {
                return [bool]$result.IsValid
            }

            [PSCustomObject]@{
                Path             = $resolvedPath
                IsValid          = $result.IsValid
                IsEncrypted      = $result.IsEncrypted
                EncryptionType   = $result.EncryptionType
                TotalEntries     = $result.TotalEntries
                EncryptedEntries = $result.EncryptedEntries
                ErrorMessage     = $result.ErrorMessage
            }
        }
        catch {
            if ($Quiet) { return $false }
            Write-Error $_
            return $null
        }
    }
}