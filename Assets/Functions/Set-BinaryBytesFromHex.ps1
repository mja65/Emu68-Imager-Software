# # function Set-BinaryBytesFromHex {
# #     param (
# #         $SourcePath,
# #         $DestinationPath,
# #         $StartOffset,
# #         $HexData
        
# #     )
    
# #     # $SourcePath = "E:\Emulators\Amiga Files\Hard Drives\OS32\Prefs\Screenmodev2"
# #     # $DestinationPath = "E:\Emulators\Amiga Files\Hard Drives\OS32\Prefs\Screenmodev2test"
# #     # $StartOffset = 50
# #     # $HexData = "50AF1303"

# #     [System.Byte[]]$FileBytes = [System.IO.File]::ReadAllBytes($SourcePath)
    
# #     for ($i = 0; $i -lt $HexData.Length; $i += 2) {
# #         $HexPair = $HexData.Substring($i, 2)
# #         $CurrentOffset = $StartOffset + ($i / 2)
        
# #         [System.Byte]$NewByte = [System.Convert]::ToByte($HexPair, 16)
# #         $FileBytes[$CurrentOffset] = $NewByte

# #     }

# #     return $FileBytes
# #     # [System.IO.File]::WriteAllBytes($DestinationPath, $FileBytes)

# # }


# function Get-RevisedBinary {
#     param (
#         $SourceBytes,
#         $StartOffset,
#         $HexData
#     )
    
#     # $StartOffset = 50
#     # $HexData = "50AF1303"
    
#     # $SourceBytes = [System.Byte[]][System.IO.File]::ReadAllBytes("E:\Emulators\Amiga Files\Hard Drives\OS32\Prefs\Screenmodev2")

#     #$BytestoReturn = $SourceBytes

#     for ($i = 0; $i -lt $HexData.Length; $i += 2) {
#         $HexPair = $HexData.Substring($i, 2)
#         $CurrentOffset = $StartOffset + ($i / 2)
        
#         [System.Byte]$NewByte = [System.Convert]::ToByte($HexPair, 16)
#         $SourceBytes[$CurrentOffset] = $NewByte

#     }

#     return $SourceBytes

# }

# function Get-RevisedScreenMode {
#     param (
#         $SourcePath,
#         $ScreenMode,
#         $ColourDepth
#         )
        
#         $SourcePath = "E:\Emulators\Amiga Files\Hard Drives\OS32\Prefs\Screenmodev2"
#         $ScreenMode = "50AF1303"
#         $ColourDepth = "03" # 8 colours
        
#         $ColourDepthToUse = [Convert]::ToString(24, 16)
#         $SourceBytes = [System.Byte[]][System.IO.File]::ReadAllBytes($SourcePath)
        
#         $RevisedScreenModeBytes = Get-RevisedBinary -SourceBytes $SourceBytes -StartOffset 50 -HexData $ScreenMode
#         $RevisedScreenModewithColourDepthBytes = Get-RevisedBinary -SourceBytes $RevisedScreenModeBytes -StartOffset 59 -HexData $ColourDepthToUse
        
#         return $RevisedScreenModewithColourDepthBytes
        
#     }
    
#     $DestinationPath = "E:\Emulators\Amiga Files\Hard Drives\OS32\Prefs\Screenmodev2test"
#     [System.IO.File]::WriteAllBytes($DestinationPath, $RevisedScreenModewithColourDepthBytes)
#     $DestinationPath,