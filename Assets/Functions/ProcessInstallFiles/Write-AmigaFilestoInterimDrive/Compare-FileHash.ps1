function Compare-FileHash {
    param (
        $FiletoCheck,
        $HashtoCheck,
        $RunParallel
    )

    If ($RunParallel -eq $false){
        Write-InformationMessage -Message "Checking hash for file: $FiletoCheck"
    }
    
    $HashChecked = Get-FileHash $FiletoCheck -Algorithm MD5
    $HashtoReport=$HashChecked.Hash
    
    if ($HashChecked.Hash -eq $HashtoCheck) {
        If ($RunParallel -eq $false){
            Write-InformationMessage -Message "Hash of file matches!"
        }
        return $true
    } 
    else{
        If ($RunParallel -eq $false){
            Write-ErrorMessage -Message "Hash mismatch! Hash expected was: $HashtoCheck. Hash found was: $HashtoReport"
        }
        return $false
    }
}