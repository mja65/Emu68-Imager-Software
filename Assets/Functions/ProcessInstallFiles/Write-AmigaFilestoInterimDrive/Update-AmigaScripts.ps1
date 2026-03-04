function Update-AmigaScripts {
    param (
        $ScripttoModifyPath,
        $ScriptPathtoChanges,
        $ScriptEditStartPoint,
        $ScriptEditEndPoint,
        $NameofChange,
        $Action,
        [Switch]$AREXXFlag

    )

    # $ScriptPathtoChanges = "$($Script:Settings.LocationofAmigaFiles)\System\S\User-Startup_AmiSSL"
    # $ScripttoModifyPath = "$($Script:Settings.InterimAmigaDrives)\System\S\User-Startup" 
    # $ActionAdd = $true
    # $ActionInjectBefore = $false
    # $NameofChange = 'Add AmiSSL'

    # $ScriptPathtoChanges = "$($Script:Settings.LocationofAmigaFiles)\System\S\Startup-Sequence_OneTimeRun"
    # $ScripttoModifyPath = "$($Script:Settings.InterimAmigaDrives)\System\S\Startup-Sequence" 
    # $ActionAdd = $false
    # $ActionInjectBefore = $true
    # $NameofChange = 'Add OnetimeRun Section'
    # $ScriptEditStartPoint = 'Binddrivers'

    Write-InformationMessage -Message "Processing Change $NameofChange."

    $OriginalScript = Import-TextFileforAmiga -SystemType 'Amiga' -ImportFile $ScripttoModifyPath 
    $ScriptChanges = @()
    $RevisedScript = @()

    if ($Action -ne 'Remove'){
        $LinestoAdd = Import-TextFileforAmiga -SystemType 'PC' -ImportFile $ScriptPathtoChanges
    }

    if ($Action -eq 'Add'){
        Write-InformationMessage "Adding Lines to $ScripttoModifyPath"

        $ScriptChanges += ""
        $ScriptChanges += ";$NameofChange - Added by Emu68 Imager version $([string]$Script:Settings.Version) - BEGIN"
        $ScriptChanges+= ""
        $LinestoAdd | ForEach-Object {
            $ScriptChanges += $_
        }
        $ScriptChanges += ""  
        $ScriptChanges += ";$NameofChange - Added by Emu68 Imager version $([string]$Script:Settings.Version) - END"
        $ScriptChanges += ""   
        
        $RevisedScript += $OriginalScript 
        $RevisedScript += $ScriptChanges 

    }
    elseif (($Action -eq 'InjectBefore') -or ($Action -eq 'InjectAfter')){
        Write-InformationMessage "Injecting Lines to $ScripttoModifyPath"
        if ($AREXXFlag){
            $ScriptChanges += ""
            $ScriptChanges += "/*"
            $ScriptChanges += "$NameofChange - Added by Emu68 Imager version $([string]$Script:Settings.Version) - BEGIN"
            $ScriptChanges += "*/"                 
            $ScriptChanges += ""
        }
        else {
            $ScriptChanges += ""
            $ScriptChanges += ";$NameofChange - Added by Emu68 Imager version $([string]$Script:Settings.Version) - BEGIN"
            $ScriptChanges += ""            
        }

        $LinestoAdd | ForEach-Object {
            $ScriptChanges += $_
        }
        $ScriptChanges += ""    
        
        if ($AREXXFlag){
            $ScriptChanges += "/*"
            $ScriptChanges += "$NameofChange - Added by Emu68 Imager version $([string]$Script:Settings.Version) - END"
            $ScriptChanges += "*/"               
            $ScriptChanges += ""           
        }
        else {
            $ScriptChanges += ";$NameofChange - Added by Emu68 Imager version $([string]$Script:Settings.Version) - END"
            $ScriptChanges += ""     
        }

    }
    
    If ($Action -eq 'InjectBefore'){
        Write-InformationMessage -Message "Injecting new lines in script before Injection point. Injection point is: $ScriptEditStartPoint"            
        $IsInserted = $false     
        foreach ($Line in $OriginalScript) {
            if ($line -notmatch $ScriptEditStartPoint){
                $RevisedScript += $line
            }
            elseif ($line -match $ScriptEditStartPoint -and $IsInserted -eq $false){
                $RevisedScript += $ScriptChanges
                $RevisedScript += $Line
                $IsInserted = $true
            }               
        }
    }
    elseif ($Action -eq 'InjectAfter'){
        Write-InformationMessage -Message "Injecting new lines in script before Injection point. Injection point is: $ScriptEditStartPoint"     
        $IsInserted = $false  
        foreach ($Line in $OriginalScript) {
            if ($line -notmatch $ScriptEditStartPoint){
                $RevisedScript += $line
            }
            elseif ($line -match $ScriptEditStartPoint -and $IsInserted -eq $false){
                $RevisedScript += $Line
                $RevisedScript += $ScriptChanges
                $IsInserted = $true
            }               
        }
    }

    elseif ($Action -eq 'Remove'){
        Write-InformationMessage -Message "Removing lines in script between Start and End point."
          Write-InformationMessage -Message "Startpoint is `"$ScriptEditStartPoint`" Endpoint is `"$ScriptEditEndPoint`"" 
          $RemoveLine = $false
          foreach ($Line in $OriginalScript) {
            if ($line -match $ScriptEditStartPoint){
                $RemoveLine = $true
                $RevisedScript += ""
                $RevisedScript += ";$NameofChange - Section Removed by Emu68 Imager version $([string]$Script:Settings.Version)"
                $RevisedScript += ""
            }
            if ($line -match $ScriptEditEndPoint){
                $RemoveLine = $false
            }
            if ($RemoveLine -eq $false -and $line -notmatch $ScriptEditStartPoint -and $line -notmatch $ScriptEditEndPoint){
                $RevisedScript += $line
            }
        }
    }    
    
    Export-TextFileforAmiga -ExportFile $ScripttoModifyPath  -DatatoExport $RevisedScript -AddLineFeeds 'TRUE'   

    return
}