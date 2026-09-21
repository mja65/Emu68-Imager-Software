function Get-ToolTypeCommands {
    param (
        $FilePath, 
        $Type,
        $IconX,   
        $IconY,   
        $DrawerX,
        $DrawerY,
        $DrawerWidth , 
        $DrawerHeight    
    )

    $IconTypes = @{
    'Disk'    = 1; 'Drawer'  = 2; 'Tool'    = 3; 'Project' = 4
    'Garbage' = 5; 'Device'  = 6; 'Kick'    = 7; 'AppIcon' = 8
}

    $Args = @(
        if ($IconTypes.ContainsKey($type)) { "--type $($IconTypes[$type])" }
        if ($IconX -and $IconX -ne 'FREEX') { "--current-x $($IconX)" }
        if ($IconY -and $IconY -ne 'FREEY') { "--current-y $($IconY)" }
        if ($DrawerX)      { "--drawer-x $($DrawerX)" }
        if ($DrawerY)      { "--drawer-y $($DrawerY)" }
        if ($DrawerWidth)  { "--drawer-width $($DrawerWidth)" }
        if ($DrawerHeight) { "--drawer-height $($DrawerHeight)" }
    )
        
    if ($Args.Count -gt 0) {
        $ArgString = ($Args -join " ")
        return "icon update `"$FilePath`" $ArgString"
    } 
    else {
        return
    }
}    