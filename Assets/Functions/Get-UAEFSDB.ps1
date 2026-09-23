function Get-UAEFSDB {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Flags,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$AmigaName,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$NormalName,

        [Parameter(Mandatory = $false, Position = 3)]
        [string]$Comment = ""
    )

    process {
        # --- 1. Compute Header Bits (Offsets 0x0 to 0x4) ---
        $flagString = $Flags.ToUpper()
        [byte]$mask = 0

        if ($flagString.Length -eq 8) {
            if ($flagString[0] -eq 'H') { $mask = $mask -bor 0x80 }
            if ($flagString[1] -eq 'S') { $mask = $mask -bor 0x40 }
            if ($flagString[2] -eq 'P') { $mask = $mask -bor 0x20 }
            if ($flagString[3] -eq 'A') { $mask = $mask -bor 0x10 }

            if ($flagString[4] -eq '-') { $mask = $mask -bor 0x08 } # R
            if ($flagString[5] -eq '-') { $mask = $mask -bor 0x04 } # W
            if ($flagString[6] -eq '-') { $mask = $mask -bor 0x02 } # E
            if ($flagString[7] -eq '-') { $mask = $mask -bor 0x01 } # D
        } else {
            if ($flagString -like "*H*") { $mask = $mask -bor 0x80 }
            if ($flagString -like "*S*") { $mask = $mask -bor 0x40 }
            if ($flagString -like "*P*") { $mask = $mask -bor 0x20 }
            if ($flagString -like "*A*") { $mask = $mask -bor 0x10 }

            if ($flagString -notlike "*R*") { $mask = $mask -bor 0x08 }
            if ($flagString -notlike "*W*") { $mask = $mask -bor 0x04 }
            if ($flagString -notlike "*E*") { $mask = $mask -bor 0x02 }
            if ($flagString -notlike "*D*") { $mask = $mask -bor 0x01 }
        }

        # Create the 5-byte header prefix natively
        [byte[]]$headerBytes = @(0x01, 0x00, 0x00, 0x00, $mask)

        # --- Helper to Convert Text to Fixed-Width Byte Block ---
        $ToFixedByteBlock = {
            param([string]$text, [int]$totalSize)
            
            # Allocate a clean, zeroed-out byte array of exact size
            $block = [byte[]]::new($totalSize)
            
            if (-not [string]::IsNullOrEmpty($text)) {
                $srcBytes = [System.Text.Encoding]::ASCII.GetBytes($text)
                
                # Cap copy size to fit within the buffer leaving room for null termination
                $copyLength = $srcBytes.Count
                if ($copyLength -ge $totalSize) {
                    $copyLength = $totalSize - 1
                }
                
                # Blit the ASCII bytes into our clean buffer
                [System.Array]::Copy($srcBytes, $block, $copyLength)
            }
            
            return ,$block
        }

        # --- 2. Process String Payloads directly into fixed Byte Blocks ---
        $amigaNameBytes  = &$ToFixedByteBlock -text $AmigaName  -totalSize 257
        $normalNameBytes = &$ToFixedByteBlock -text $NormalName -totalSize 257
        $commentBytes    = &$ToFixedByteBlock -text $Comment    -totalSize 81

        # --- 3. Concatenate Everything into a clean 600-byte structure ---
        [byte[]]$finalRecord = [byte[]]::new(600)
        
        [System.Array]::Copy($headerBytes,      0, $finalRecord, 0,   5)
        [System.Array]::Copy($amigaNameBytes,   0, $finalRecord, 5,   257)
        [System.Array]::Copy($normalNameBytes,  0, $finalRecord, 262, 257)
        [System.Array]::Copy($commentBytes,     0, $finalRecord, 519, 81)

        return ,$finalRecord
    }
}

#Get-UAEFSDB  -Flags "----RW-D" -AmigaName "arexx.class.z" -NormalName "arexx.class.z" -Comment ""