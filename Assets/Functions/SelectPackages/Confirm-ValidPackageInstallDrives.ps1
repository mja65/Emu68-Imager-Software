function Confirm-ValidPackageInstallDrives {
    param (

    )
    
    If (-not ($Script:GUIActions.AvailablePackages)){
        return
    }
    
    $PartitionsFound = @("System")
    
    if (-not ($Script:GUICurrentStatus.AmigaPartitionsandBoundaries)){
        $Script:GUICurrentStatus.AmigaPartitionsandBoundaries = @(Get-AllGUIPartitionBoundaries -Amiga)
    }      
    Foreach ($Partition in $Script:GUICurrentStatus.AmigaPartitionsandBoundaries){
        If ($Partition.Partition.VolumeName -ne "Workbench"){
            $PartitionsFound += $Partition.Partition.VolumeName
        }
    }
    
    $FoundInvalidDrive = $false
    
    Foreach ($Package in $Script:GUIActions.AvailablePackages){
        if (($Package.UserDefinableInstallPath -eq $true) -and ($Package.PackageUserDrive -notin $PartitionsFound)){
            $Package.PackageUserDrive = $Package.DefaultDrive 
            $Package.PackageUserPath = $Package.DefaultPath
            $FoundInvalidDrive = $true
        }
    }
    
    If ($FoundInvalidDrive -eq $true){
        $Msg_Header = 'Invalid Drives'   
        $Msg_Body = 'One or more packages was set to install to a drive (or drives) that are no longer part of the installation! These packages have been reset to the default install paths. Please go to the Package Selection screen should you wish to change.'
        $null = Show-WarningorError -Msg_Body $Msg_Body -Msg_Header $Msg_Header -BoxTypeWarning -ButtonType_OK 
    }
        
}


