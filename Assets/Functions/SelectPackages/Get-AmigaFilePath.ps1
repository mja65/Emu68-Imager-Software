function Get-AmigaFilePath {
    param (
        $InputFilePath
    )
    
    if ($InputFilePath -match '^(?=.{1,70}$)(?:(?![\/\\]{2,})[a-zA-Z0-9 /\\ ])+$') {
        return $InputFilePath.replace('/','\').TrimEnd('\')
    } else {
        return 
    }

}
