function Get-RevisedBinary {
    param (
        $SourceBytes,
        $StartOffset,
        $HexData
    )
    
    # $StartOffset = 50
    # $HexData = "50AF1303"
     # $HexData = "00029004"

    # $SourceBytes = [System.Byte[]][System.IO.File]::ReadAllBytes("E:\Emulators\Amiga Files\Hard Drives\OS32\Prefs\Screenmodev2")

    #$BytestoReturn = $SourceBytes

    for ($i = 0; $i -lt $HexData.Length; $i += 2) {
        $HexPair = $HexData.Substring($i, 2)
        $CurrentOffset = $StartOffset + ($i / 2)
        
        [System.Byte]$NewByte = [System.Convert]::ToByte($HexPair, 16)
        $SourceBytes[$CurrentOffset] = $NewByte

    }

    return $SourceBytes

}

