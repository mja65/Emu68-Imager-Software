function Get-DeviceandVolumeNametoUse {
    param (

    )
    
    $OutputtoReturn  = [PSCustomObject]@{
        DeviceName = $null
        VolumeName = $null
    }
    
    $VolumeNameSystem = "$((Get-InputCSVs -Diskdefaults | Where-Object {$_.Disk -eq "System"}).VolumeName)"
    $VolumeNameWork = "$((Get-InputCSVs -Diskdefaults | Where-Object {$_.Disk -eq "Work"}).VolumeName)"

    $VolumeNameWorkPrefix = "$($VolumeNameWork)_"
    $DeviceNamePrefix = (Get-InputCSVs -Diskdefaults | Where-Object {$_.Disk -eq "Work"}).devicename -replace "\d", "" 

    
    $DeviceNumbertoUse = 0
    $IsDeviceNumberFound = $false

    ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Select-Object 'Partition').Partition.DeviceName | Sort-Object | ForEach-Object {
        $DeviceNameNumber = $_ -replace $DeviceNamePrefix, ""
        if (($DeviceNumbertoUse -ne $DeviceNameNumber) -and ($IsDeviceNumberFound -eq $false)) {
            $IsDeviceNumberFound = $true
            $OutputtoReturn.DeviceName = "$DeviceNamePrefix$DeviceNumbertoUse"             
        }
        $DeviceNumbertoUse ++
    }

    if ($IsDeviceNumberFound -eq $false){
        $OutputtoReturn.DeviceName = "$DeviceNamePrefix$DeviceNumbertoUse" 
    }

    if (-not (($Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Select-Object 'Partition').Partition.VolumeName | Where-Object {$_ -eq $VolumeNameWork})) {
        $OutputtoReturn.VolumeName =  $VolumeNameWork
    } 

    if (-not ($OutputtoReturn.VolumeName)){
        $VolumeNameCountertoUse = 1
        $IsVolumeNameFound = $false
        ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries | Select-Object 'Partition').Partition.VolumeName | Where-Object {($_ -ne $VolumeNameSystem) -and ($_ -ne $VolumeNameWork) -and ($_ -match $VolumeNameWorkPrefix)}  | Sort-Object | ForEach-Object {
           $VolumeCountertoCheck = [int]($_-replace $VolumeNameWorkPrefix,"")
           if (($VolumeNameCountertoUse -ne $VolumeCountertoCheck) -and ($IsVolumeNameFound -eq $false)){
               $IsVolumeNameFound = $true
               $OutputtoReturn.VolumeName = "$VolumeNameWorkPrefix$VolumeNameCountertoUse"
           }
           $VolumeNameCountertoUse ++
        
        }
        
        if ($IsVolumeNameFound -eq $false){
            $OutputtoReturn.VolumeName = "$VolumeNameWorkPrefix$VolumeNameCountertoUse"
        }

    }
    return $OutputtoReturn
}