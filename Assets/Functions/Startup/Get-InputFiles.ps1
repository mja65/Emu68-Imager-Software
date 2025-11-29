function Get-InputFiles {
    param (

    )

    Write-InformationMessage "Checking for existence of InputFileCSVs and downloading where missing or changed"
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.StartupFilesCSV.GID -ExistingCSV  $Script:Settings.StartupFilesCSV.Path
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.OSVersionstoInstallCSV.GID -ExistingCSV  $Script:Settings.OSVersionstoInstallCSV.Path
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.IconSetsCSV.GID -ExistingCSV  $Script:Settings.IconSetsCSV.Path
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.ROMHashesCSV.GID -ExistingCSV  $Script:Settings.ROMHashesCSV.Path
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.InstallMediaHashesCSV.GID -ExistingCSV  $Script:Settings.InstallMediaHashesCSV.Path
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.ListofPackagestoInstallCSV.GID -ExistingCSV $Script:Settings.ListofPackagestoInstallCSV.Path
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.ScreenModesCSV.GID -ExistingCSV $Script:Settings.ScreenModesCSV.Path
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.ScreenModesWBCSV.GID -ExistingCSV $Script:Settings.ScreenModesWBCSV.Path    
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.AminetMirrorsCSV.GID -ExistingCSV $Script:Settings.AminetMirrorsCSV.Path
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.FileSystemsCSV.GID -ExistingCSV $Script:Settings.FileSystemsCSV.Path
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.DiskDefaultsCSV.GID -ExistingCSV $Script:Settings.DiskDefaultsCSV.Path
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.IconPositionsCSV.GID -ExistingCSV $Script:Settings.IconPositionsCSV.Path
    Update-InputCSV -PathtoGoogleDrive $Script:Settings.InputFiles.InputFileSpreadsheetURL -GidValue $Script:Settings.DocumentationURLsCSV.GID -ExistingCSV $Script:Settings.DocumentationURLsCSV.Path

}