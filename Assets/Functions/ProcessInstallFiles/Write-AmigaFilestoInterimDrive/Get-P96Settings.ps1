function Get-P96Settings {
    param (
        $Resolutions,
        $GlobalRefreshRate,
        $BaseDisplayID,
        $P96Version
    )
    
    # $BaseDisplayID = 0x50001000 
    # $Resolutions = $Script:GUIActions.SelectedP96Resolutions

    $BoardType = if ($P96Version -eq "3.x") { 39 } else { 14 }

    $ResolutionstoPopulate = $Resolutions | Sort-Object
    
    $P96Settings = [PSCustomObject]@{
        PSTypeName     = "Picasso96.Settings"
        Annotation     = [PSCustomObject]@{
            PSTypeName = "Picasso96.Annotation"
            Text       = "p96p"
        }
        SettingsHeader = [PSCustomObject]@{
            PSTypeName    = "Picasso96.SettingsHeader"
            BoardType     = $BoardType
            LocalOrdering = 0
            LastSelected  = 0
            Name          = "Videocore"
        }        
        MonitorInfo    =  [PSCustomObject]@{
            PSTypeName   = "Picasso96.MonitorInfo"
            Name         = $null
            HSyncMin     = $null
            HSyncMax     = $null
            VSyncMin     = $null
            VSyncMax     = $null
            Flags        = $null
        }            
        BoardName      = [PSCustomObject]@{
            PSTypeName   = "Picasso96.BoardName"
            Name         = "Videocore"
        }
        Resolutions    = [System.Collections.Generic.List[object]]::new()               
    }

    $DisplayID = $BaseDisplayID

    foreach ($Resolution in $ResolutionstoPopulate){
        $WidthHeight = $Resolution.replace("RTG:","").split("x")
        $Width = $WidthHeight[0]
        $Height = $WidthHeight[1]
        $NewResolution = New-P96Resolution -DisplayID $DisplayID -Width $Width -Height $Height -RefreshRateHz 60 -Depths @(8, 16, 24, 32) -Name "Videocore:$($Width)x$($Height)"
        $P96Settings.Resolutions.Add($NewResolution)
        $DisplayID += 0x10000
    }
    
    return $P96Settings

}