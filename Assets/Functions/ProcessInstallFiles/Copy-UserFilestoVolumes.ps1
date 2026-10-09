function Copy-UserFilestoVolumes {
    param (

    )

    $UserVolumesPath = [System.IO.Path]::GetFullPath($Script:Settings.UserVolumeFilesLocation)

    if (-not (Test-Path -Path $UserVolumesPath -PathType Container)){
        return
    }

    $VolumeFolders = Get-ChildItem -Path $UserVolumesPath -Directory -ErrorAction SilentlyContinue

    if (-not $VolumeFolders){
        return
    }

    $Script:Settings.CurrentTaskName = "Copying your own files to the Amiga volumes"
    Write-StartTaskMessage

    $Script:Settings.TotalNumberofSubTasks = @($VolumeFolders).Count
    $Script:Settings.CurrentSubTaskNumber = 0

    $VolumeFolders.ForEach({
        $UserFolder = $_

        $Script:Settings.CurrentSubTaskNumber ++
        $Script:Settings.CurrentSubTaskName = "Copying files for volume $($UserFolder.Name)"
        Write-StartSubTaskMessage

        # The staging folder is named after the volume, except the Workbench volume
        # which is staged as "System" -- the same naming Get-CopyFilestoDiskCommands
        # uses when it copies the staged tree onto the real partitions.
        $DestinationPath = Join-PathMulti $Script:Settings.InterimAmigaDrives $UserFolder.Name -UseFullPath

        if (-not (Test-Path -Path $DestinationPath -PathType Container)){
            Write-InformationMessage -Message "No volume named $($UserFolder.Name) in this image -- skipping those files"
            return
        }

        $ItemstoCopy = Get-ChildItem -Path $UserFolder.FullName -Force -ErrorAction SilentlyContinue

        if (-not $ItemstoCopy){
            return
        }

        Write-InformationMessage -Message "Copying your files to volume $($UserFolder.Name)"

        $ItemstoCopy.ForEach({
            $null = Copy-Item -Path $_.FullName -Destination $DestinationPath -Recurse -Force -ErrorAction SilentlyContinue
        })
    })

    Write-TaskCompleteMessage
}
