$DropDownScaleOptions = @()
$DropDownScaleOptions += New-Object -TypeName pscustomobject -Property @{Scale='TiB'}
$DropDownScaleOptions += New-Object -TypeName pscustomobject -Property @{Scale='GiB'}
$DropDownScaleOptions += New-Object -TypeName pscustomobject -Property @{Scale='MiB'}
$DropDownScaleOptions += New-Object -TypeName pscustomobject -Property @{Scale='KiB'}
$DropDownScaleOptions += New-Object -TypeName pscustomobject -Property @{Scale='B'}

foreach ($Option in $DropDownScaleOptions){
    $WPF_NewImageSizeWindow_Input_ImageSize_SizeScale_Dropdown.AddChild($Option.Scale)
}

# Write-debug "Default scale to use is: $($Script:GUICurrentStatus.ImageSizeDefaultScale)"
$WPF_NewImageSizeWindow_Input_ImageSize_SizeScale_Dropdown.SelectedItem = $Script:GUICurrentStatus.ImageSizeDefaultScale
# Write-debug "Default scale used is: $($WPF_NewImageSizeWindow_Input_ImageSize_SizeScale_Dropdown.SelectedItem)"

$WPF_NewImageSizeWindow_Input_ImageSize_SizeScale_Dropdown.add_selectionChanged({
    $WPF_NewImageSizeWindow_Input_ImageSize_Value.InputEntryScaleChanged = $true
 })
