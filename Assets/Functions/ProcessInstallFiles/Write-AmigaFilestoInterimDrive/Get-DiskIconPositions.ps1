function Get-DiskIconPositions {
    param (
        $ListofDisks
    )
    
    $DefaultDisks = Get-InputFileCSV -CSV 'DiskDefaults'
    
    #$ListofDisks = ($CombinedDiskIconstoAdd.VolumeName).where({$_ -ne "NewFolder"})
       
    $HashTableforDefaultDisks = @{}
    
    foreach ($Disk in $DefaultDisks) {
        $HashTableforDefaultDisks[$Disk.VolumeName] = $Disk
    }
    
    $HighestIconY = [int]0
    
    $DiskIconPositions = foreach ($Disk in $ListofDisks) {
    
        $Matched = $HashTableforDefaultDisks[$Disk]
        
        $HighestIconY = if (([int]$Matched.IconY) -gt $HighestIconY) {([int]$Matched.IconY)} else {$HighestIconY } 
        if ($Matched){
            [pscustomobject]@{
                Volume  = $Disk
                Match   = $true
                IconX   = [int]$Matched.IconX
                IconY   = [int]$Matched.IconY
                DrawerX = [int]$Matched.DrawerX
                DrawerY = [int]$Matched.DrawerY
                DWidth  = [int]$Matched.DWidth
                DHeight = [int]$Matched.DHeight
            }
        }
        else {
            [pscustomobject]@{
                Volume  = $Disk
                Match   = $false
                IconX   = $null
                IconY   = $null
                DrawerX = $null
                DrawerY = $null
                DWidth  = $null
                DHeight = $null          
            }
        }
    }
    
    $DiskIconPositions.where({$_.Match -eq $false}).foreach({
        $NewIconY = ($HighestIconY + [int]$($Script:Settings.AmigaWorkDiskIconYPositionSpacing))
        $HighestIconY = $NewIconY 
        $_.IconX  = $Script:Settings.AmigaWorkDiskIconXPosition 
        $_.IconY   = $NewIconY
        $_.DrawerX = $Script:Settings.AmigaWorkDiskDrawerX
        $_.DrawerY = $Script:Settings.AmigaWorkDiskDrawerY
        $_.DWidth  = $Script:Settings.AmigaWorkDiskDwidth 
        $_.DHeight = $Script:Settings.AmigaWorkDiskDHeight
    })

    return $DiskIconPositions

}


  
