function Get-NewImageSize {
    param (
    $DefaultScale

    )

    #$DefaultScale = "GiB" 
    #$MaximumSizeBytes = 332365824
    #$MinimumSizeBytes = 10*1024*1024    
    #$WPF_NewImageSizeWindow_Input_ImageSize_Value.Text = '5000' 

    $MinimumSizeBytestoUse = (Get-ConvertedSize -Size $MinimumSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2)
    $MaximumSizeBytestoUse = (Get-ConvertedSize -Size $MaximumSizeBytes -ScaleFrom 'B' -AutoScale -NumberofDecimalPlaces 2 -Truncate)

    $Script:GUICurrentStatus.ImageSizeDefaultScale = $DefaultScale

    Remove-Variable -Name 'WPF_NewImageSizeWindow_*'
    
    $WPF_NewImageSizeWindow = Get-XAML -WPFPrefix 'WPF_NewImageSizeWindow_' -XMLFile '.\Assets\WPF\Window_SetImageSize.xaml'  -ActionsPath '.\Assets\UIActions\NewImageSizeWindow\' -AddWPFVariables
       
    $null = $WPF_NewImageSizeWindow_Input_ImageSize_Value.Focus()
    $WPF_NewImageSizeWindow_Input_ImageSize_Value.SelectionLength = $WPF_NewImageSizeWindow_Input_ImageSize_Value.Text.Length
    $WPF_NewImageSizeWindow_Input_ImageSize_Value.SelectionStart = 0
    
    $WPF_NewImageSizeWindow.ShowDialog() | out-null

    $Script:GUICurrentStatus.ImageSizeDefaultScale = $null

    if ($Script:GUICurrentStatus.ImageSizeAcceptedValue -eq $true){
        if ($WPF_NewImageSizeWindow_Input_ImageSize_Value.Text){
            $ValuetoReturn = (Get-ConvertedSize -Size $WPF_NewImageSizeWindow_Input_ImageSize_Value.Text -ScaleFrom $WPF_NewImageSizeWindow_Input_ImageSize_SizeScale_Dropdown.SelectedItem -Scaleto 'B').size  
            Remove-Variable -Name 'WPF_NewImageSizeWindow_*'
            $Script:GUICurrentStatus.ImageSizeAcceptedValue = $false
            return $ValuetoReturn
        }
        else {
            Remove-Variable -Name 'WPF_NewImageSizeWindow_*'
            return 
        }                          
    }
    else {
        Remove-Variable -Name 'WPF_NewImageSizeWindow_*'
        return 
    }
    
}
