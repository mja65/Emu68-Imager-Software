function Update-Emu68ImagerDocumentation {
    param (
        $Emu68ImagerDocumentationPath
    )

   # $Emu68ImagerDocumentationPath = 'E:\PiStorm\Docs\test.html'
   

    $URLContent = Get-Content $Emu68ImagerDocumentationPath

    $RevisedURLContent = foreach ($Line in $URLContent){
        if ((([System.IO.Path]::GetFileName($Emu68ImagerDocumentationPath)) -eq "Emu68-Imager.html") -or (([System.IO.Path]::GetFileName($Emu68ImagerDocumentationPath)) -eq "index.html")) {
            $Line = $Line -replace '<a href="/Emu68-Imager/', '<a href="./html/'
            $Line = $Line -replace '<a href="https://mja65.github.io/Emu68-Imager/', '<a href="./index.html'
            $Line = $Line -replace '<img src="/Emu68-Imager/images' , '<img src="./images'                        
        }
        else{
            $Line = $Line -replace '<a href="/Emu68-Imager/', '<a href="../html/'
            $Line = $Line -replace '<a href="https://mja65.github.io/Emu68-Imager/', '<a href="../index.html'
            $Line = $Line -replace '<img src="/Emu68-Imager/images' , '<img src="../images'
        }
        $Line
    }
    set-content $Emu68ImagerDocumentationPath -Value $RevisedURLContent

    return

}
                             