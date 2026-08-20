function Compare-FileHash {
    param (
        $FiletoCheck,
        $HashtoCheck
    )
    $Algorithm = 'MD5'
    if ($HashtoCheck -match '^sha256:') {
        $Algorithm = 'SHA256'
        $HashtoCheck = $HashtoCheck -replace '^sha256:', ''
    }
    elseif ($HashtoCheck -match '^[a-fA-F0-9]{64}$') {
        $Algorithm = 'SHA256'
    }

    Write-InformationMessage -Message "Checking $Algorithm hash for file: $FiletoCheck"
    $HashChecked = Get-FileHash -LiteralPath $FiletoCheck -Algorithm $Algorithm
    $HashtoReport=$HashChecked.Hash
    if ($HashChecked.Hash -eq $HashtoCheck) {
        Write-InformationMessage -Message "Hash of file matches!"
        return $true
    } 
    else{
        Write-ErrorMessage -Message "Hash mismatch! Hash expected was: $HashtoCheck. Hash found was: $HashtoReport"
        return $false
    }
        
}
