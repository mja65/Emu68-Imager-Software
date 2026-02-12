function Get-UnicamConfigTxt {
    param (

    )

    if ($Script:GUIActions.UnicamEnabled -eq $true){
        $Line = "dtoverlay=unicam"
        If ($Script:GUIActions.UnicamStartonBoot -eq $true){
            $Line += "$line,boot"
        }
        if ($Script:GUIActions.UnicamScalingType -eq "Smooth"){
            $Line += ",smooth,b=$($Script:GUIActions.UnicamBParameter),c=$($Script:GUIActions.UnicamCParameter)"
        }
        elseif ($Script:GUIActions.UnicamScalingType -eq "Integer"){
            $Line += ",integer"
        }
        
        return $line
    }
    else {
        return
    }

}