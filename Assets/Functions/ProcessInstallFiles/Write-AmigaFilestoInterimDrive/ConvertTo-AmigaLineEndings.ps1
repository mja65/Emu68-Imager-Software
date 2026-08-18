function ConvertTo-AmigaLineEndings {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Path
    )

    foreach ($FilePath in $Path) {
        if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
            continue
        }

        $InputBytes = [System.IO.File]::ReadAllBytes($FilePath)
        $OutputBytes = [System.Collections.Generic.List[byte]]::new($InputBytes.Length)
        $Changed = $false

        for ($Index = 0; $Index -lt $InputBytes.Length; $Index++) {
            if (($InputBytes[$Index] -eq 13) -and
                ($Index + 1 -lt $InputBytes.Length) -and
                ($InputBytes[$Index + 1] -eq 10)) {
                $Changed = $true
                continue
            }

            $OutputBytes.Add($InputBytes[$Index])
        }

        if ($Changed) {
            Write-InformationMessage -Message "Converting Amiga text file to LF line endings: $FilePath"
            [System.IO.File]::WriteAllBytes($FilePath, $OutputBytes.ToArray())
        }
    }
}
