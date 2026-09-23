function Read-UAEFSDB {
    param(
        [string]$Path
    )
 
    process {
        $Path = (join-path $Path "_UAEFSDB.___")
        # Open a binary file stream for reading
        $fileStream = [System.IO.File]::OpenRead($Path)
        $buffer = New-Object byte[] 600
        $AmigaEncoding = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
        $HostEncoding  = [System.Text.Encoding]::UTF8

        try {
            while (($bytesRead = $fileStream.Read($buffer, 0, 600)) -eq 600) {
                $validFlag = $buffer[0]
                $mask = $buffer[4]
                $protectionString = [char[]]@('-', '-', '-', '-', '-', '-', '-', '-')
                
                if ($mask -band 0x80) { $protectionString[0] = 'H' }
                if ($mask -band 0x40) { $protectionString[1] = 'S' }
                if ($mask -band 0x20) { $protectionString[2] = 'P' }
                if ($mask -band 0x10) { $protectionString[3] = 'A' }
                
                if (($mask -band 0x08) -eq 0) { $protectionString[4] = 'R' }
                if (($mask -band 0x04) -eq 0) { $protectionString[5] = 'W' }
                if (($mask -band 0x02) -eq 0) { $protectionString[6] = 'E' }
                if (($mask -band 0x01) -eq 0) { $protectionString[7] = 'D' }

                $flagsResult = -join $protectionString

                # --- Helper to Extract Null-Terminated ASCII Strings ---
                $GetNullTerminatedString = {
                    param([byte[]]$block, [int]$offset, [int]$maxLen, $encodingEngine)
                    
                    # Find where the actual string ends (at the 0x00 null byte)
                    $endIndex = $offset
                    while ($endIndex -lt ($offset + $maxLen) -and $block[$endIndex] -ne 0) {
                        $endIndex++
                    }
                    
                    # Extract the sub-array and convert to text
                    $stringLength = $endIndex - $offset
                    if ($stringLength -gt 0) {
                        return $encodingEngine.GetString($block, $offset, $stringLength)
                    }
                    return ""
                }

                # --- 2. Extract Names and Comments via Offsets ---

                $amigaName  = &$GetNullTerminatedString -block $buffer -offset 5   -maxLen 257 -encodingEngine $AmigaEncoding
                $normalName = &$GetNullTerminatedString -block $buffer -offset 262 -maxLen 257 -encodingEngine $HostEncoding
                $comment    = &$GetNullTerminatedString -block $buffer -offset 519 -maxLen 81  -encodingEngine $AmigaEncoding

                # --- 3. Emit Custom PowerShell Object ---
                [PSCustomObject]@{
                    AmigaName        = $amigaName
                    NormalName       = $normalName
                    ProtectionString = $flagsResult
                    Comment          = $comment
                   # RawMaskHex       = "00 00 00 {0:X2}" -f $mask
                }
            }
        }
        finally {
            $fileStream.Close()
            $fileStream.Dispose()
        }
    }
}

# Read-UAEFSDB -Path "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\InterimAmigaDrives\System\Locale\Catalogs" | Format-Table -AutoSize

function Test-AmigaFilenameCompatibility {
    <#
    .SYNOPSIS
        Scans a local host folder for filenames that will break or mangle under Amiga ISO-8859-1 encoding.
    .DESCRIPTION
        Evaluates files recursively, identifying illegal characters and text encoding limits.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    process {
        if (-not (Test-Path $Path)) {
            Write-Error "The specified path does not exist: $Path"
            return
        }

        # --- Fix: Robust Strict Latin-1 (ISO-8859-1) initialization ---
        # Code page 28591 is ISO-8859-1. We pass Exception Fallbacks for both 
        # encoding and decoding to guarantee it blows up instantly on bad characters.
        try {
            $EncFallback = [System.Text.EncoderFallback]::ExceptionFallback
            $DecFallback = [System.Text.DecoderFallback]::ExceptionFallback
            $StrictAmigaEncoding = [System.Text.Encoding]::GetEncoding(28591, $EncFallback, $DecFallback)
        }
        catch {
            Write-Error "Failed to initialize strict Latin-1 encoding subsystem: $_"
            return
        }

        Write-Host "Scanning directory tree for Amiga filesystem compatibility issues..." -ForegroundColor Cyan

        # Fetch all files and directories recursively
        $items = Get-ChildItem -Path $Path -Recurse

        $report = foreach ($item in $items) {
            $issues = [System.Collections.Generic.List[string]]::new()
            $name = $item.Name

           # --- 3. Check for Latin-1 Encoding Violations ---
            try {
                # This will now safely trigger the catch block if an invalid char hits it
                $null = $StrictAmigaEncoding.GetBytes($name)
            }
            catch {
                $issues.Add("Contains non-Latin-1 characters (Cannot map to Amiga encoding)")
            }

            # If any structural or encoding rules were broken, log it
            if ($issues.Count -gt 0) {
                [PSCustomObject]@{
                    ItemType     = if ($item.PSIsContainer) { "Directory" } else { "File" }
                    HostFilename = $name
                    RelativePath = $item.FullName.Replace($Path, "")
                    Issues       = $issues -join " | "
                }
            }
        }

        if ($null -eq $report) {
            Write-Host "Success! All filenames are completely compatible with the Amiga environment." -ForegroundColor Green
        } else {
            return $report
        }
    }
}

#Test-AmigaFilenameCompatibility -Path "C:\Users\Matt\OneDrive\Documents\DiskPartitioner\Temp\InterimAmigaDrives" | Format-Table -AutoSize