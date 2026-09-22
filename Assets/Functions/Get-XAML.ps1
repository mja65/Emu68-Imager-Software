function Get-XAML {
    param (
        $WPFPrefix,
        $XMLFile,
        $ActionsPath,
        [switch]$AddWPFVariables 

    )

    # $XMLFile = '.\Assets\WPF\Main_Window_Simple.xaml'
    # $XMLFile = '.\Assets\WPF\Grid_DiskPartition.xaml'
    # $WPFPrefix = 'Test'

    [xml]$ParsedXML = (get-content $XMLFile) -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
   
    # if (($Script:GUICurrentStatus.OperationMode -eq "Simple") -and ($ParsedXML.Window.Title -eq "Emu68 Imager")){
    #     $ParsedXML.Window.'Window.Background'.ImageBrush.ImageSource = [System.IO.Path]::GetFullPath(".\Assets\WPF\Backgrounds\Background.png") -replace ("\\","/")
    # }

    $reader = (New-Object System.Xml.XmlNodeReader $ParsedXML)

    try{
        $XAMLtoReturn = [Windows.Markup.XamlReader]::Load( $reader )
    }
    catch{
        Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
        throw
    }
   
    if ($AddWPFVariables){
        $ParsedXML.SelectNodes("//*[@Name]") | Where-Object {$_.Name -notmatch 'Window'} | ForEach-Object{
            Set-Variable -Scope Script -Name "$WPFPrefix$($_.Name)" -Value $XAMLtoReturn.FindName($_.Name) 
        }
    }

    if ($ActionsPath){
        Get-ChildItem -Path $ActionsPath -File | ForEach-Object {
           # Write-host "$($_)"
            . ($_).fullname
        }
    }
    
    return $XAMLtoReturn

} 
