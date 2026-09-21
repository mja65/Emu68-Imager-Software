function Export-TextFile {
    param (
        [switch]$Amiga,
        [switch]$PC,
        $ExportFile,
        $DatatoExport,
        [switch]$AddLineFeeds
    )
    Write-InformationMessage -Message "Exporting file $ExportFile"

    if ($AddLineFeeds){
        Write-InformationMessage -Message "Adding line feeds to file $ExportFile"
        $DatatoExportRevised = $DataToExport.Replace("`r", "")
        $ContentToExport = $DatatoExportRevised -join "`n"
    }
    else {
        $ContentToExport = $DatatoExport        
    }
    
    If ($Amiga){
        $Encoding = [System.Text.Encoding]::GetEncoding('iso-8859-1')
    }
    elseif ($PC){
        $Encoding = New-Object System.Text.UTF8Encoding($false)        
    }
    
    [System.IO.File]::WriteAllText($ExportFile,$ContentToExport,$Encoding)

}