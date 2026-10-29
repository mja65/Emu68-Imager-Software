function Expand-PasswordZip {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [string]$Password = "",

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$Quiet,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    process {
        try {
            $resolvedZip = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
            $resolvedDest = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)

            if (-not (Test-Path -LiteralPath $resolvedZip -PathType Leaf)) {
                if ($Quiet) { return $false }
                throw (New-Object System.IO.FileNotFoundException("ZIP file not found at '$resolvedZip'", $resolvedZip))
            }

            if (-not (Test-Path -LiteralPath $resolvedDest -PathType Container)) {
                New-Item -ItemType Directory -Path $resolvedDest -Force -ErrorAction SilentlyContinue | Out-Null
            }

            if ($PSCmdlet.ShouldProcess("$resolvedZip", "Extract to '$resolvedDest'")) {
                if (-not $Quiet) {
                    Write-Verbose "Validating archive password for: $resolvedZip"
                }

                $test = [PowerShellZip.ZipDecryptor]::TestArchive($resolvedZip, $Password)

                if (-not $test.IsValid) {
                    if ($Quiet) { return $false }
                    throw (New-Object System.InvalidOperationException(
                        "Extraction aborted. Password check failed: $($test.ErrorMessage)"
                    ))
                }

                if (-not $Quiet) {
                    Write-Verbose "Extracting $($test.TotalEntries) entries ($($test.EncryptionType))..."
                }

                $extractedList = [PowerShellZip.ZipDecryptor]::Extract($resolvedZip, $resolvedDest, $Password, [bool]$Force)

                if (-not $Quiet) {
                    Write-Verbose "Successfully extracted $($extractedList.Count) files."
                }

                if ($Quiet) {
                    return $true
                }

                if ($PassThru) {
                    return $extractedList
                }
            }
        }
        catch {
            if ($Quiet) {
                return $false
            }
            throw $_
        }
    }
}
