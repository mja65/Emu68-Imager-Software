function Join-PathMulti {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0, ValueFromRemainingArguments = $true)]
        [AllowEmptyString()]
        [string[]]$Path,

        [Switch]$UseFullPath,
        [switch]$ExtendedPrefix
    )

    process {
        $CleanPath = @($Path).Where({ -not [string]::IsNullOrWhiteSpace($_) })

        if ($CleanPath.Count -eq 0) {
            return ""
        }

        $ResultPath = $CleanPath[0]

        $ResultPath = [System.IO.Path]::Combine($CleanPath)

        if ($UseFullPath -and -not [string]::IsNullOrWhiteSpace($ResultPath)) {
            try {
                $ResultPath = [System.IO.Path]::GetFullPath($ResultPath)
                if ($ExtendedPrefix) {
                    $ResultPath = "\\?\$ResultPath"
                }
                return $ResultPath                
            }
            catch {
                if ($ExtendedPrefix) {
                    $ResultPath = "\\?\$ResultPath"
                }
                return $ResultPath
            }
        }

        if ($ExtendedPrefix) {
            $ResultPath = "\\?\$ResultPath"
        }
        return $ResultPath
    }
}