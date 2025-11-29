function Check-WBScreenMode {
    param (

    )
    
    $ChipsetMinimum = $null

    $Script:GUIActions.AvailableScreenModesWB | ForEach-Object {
        if ($_.FriendlyName -eq $Script:GUIActions.ScreenModetoUseWB){
            if (($_.Type -eq "AGA") -or ($_.Type -eq "RTG")){
                $ChipsetMinimum = $_.Type
            }
            elseif ($Script:GUIActions.ScreenModeWBColourDepth -gt $_.MaxDepthECS) {
                $ChipsetMinimum = "AGA"
            }
            elseif (($Script:GUIActions.ScreenModeWBColourDepth -gt $_.MaxDepthOCS) -and ($Script:GUIActions.ScreenModeWBColourDepth -le $_.MaxDepthECS)) {
                $ChipsetMinimum = "ECS"
            }
            else {
                $ChipsetMinimum = $_.Type
            }
        }

    }

    return $ChipsetMinimum
}