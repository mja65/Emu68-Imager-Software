function Get-NumberOfColours {
    param (
        $ColourDepth
    )
    
#    $ColourDepth = 24

    $NumberofColours = [bigint]::Pow(2, $ColourDepth)

    if ($NumberofColours -gt 256){
        $NumberofColours = [Math]::Truncate((([decimal]$NumberofColours/1000000)*10))/10

        $NumberofColoursToReturn = "$([string]$NumberofColours)M"
    }
    else {
        $NumberofColoursToReturn = [string]$NumberofColours

    }

    return $NumberofColoursToReturn 
    
}