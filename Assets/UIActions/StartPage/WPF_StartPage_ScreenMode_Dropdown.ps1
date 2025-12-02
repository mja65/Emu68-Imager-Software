# $AvailableScreenModes = Import-Csv ($InputFolder+'ScreenModes.csv') -delimiter ';' | Where-Object 'Include' -eq 'TRUE'

$Script:GUIActions.AvailableScreenModes = Get-InputCSVs -ScreenModes

foreach ($ScreenMode in $Script:GUIActions.AvailableScreenModes) {
    $WPF_StartPage_ScreenMode_Dropdown.AddChild($ScreenMode.FriendlyName)
}

$Script:GUIActions.ScreenModetoUseFriendlyName = 'Automatic'
$WPF_StartPage_ScreenMode_Dropdown.SelectedItem = $Script:GUIActions.ScreenModetoUseFriendlyName 
$Script:GUIActions.ScreenModetoUse = 'Auto'

$WPF_StartPage_ScreenMode_Dropdown.Add_SelectionChanged({
    $PIScreenModeDetails = ($Script:GUIActions.AvailableScreenModes | Where-Object {$_.FriendlyName -eq $WPF_StartPage_ScreenMode_Dropdown.SelectedItem})
    
    $Script:GUIActions.ScreenModetoUse = $PIScreenModeDetails.Name
    $Script:GUIActions.ScreenModetoUseFriendlyName = $PIScreenModeDetails.FriendlyName
    
    $isRTG = $Script:GUIActions.ScreenModeType -eq "RTG"
    
    if ($isRTG){
        $WBScreenModeDetails = ($Script:GUIActions.AvailableScreenModesWB | Where-Object {$_.FriendlyName -eq $Script:GUIActions.ScreenModetoUseWB -and $_.RTG -eq $true})
        $WPF_StartPage_ScreenModeWorkbench_Dropdown.Items.Clear()
        If ($Script:GUIActions.ScreenModetoUseFriendlyName -eq 'Automatic'){
            $Script:GUIActions.AvailableScreenModesWB | Where-Object {$_.RTG -eq $isRTG} | ForEach-Object {
                $WPF_StartPage_ScreenModeWorkbench_Dropdown.AddChild($_.FriendlyName)
            }
            $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem = $Script:GUIActions.ScreenModetoUseWB    
        }
        else {
            if (([int]$PIScreenModeDetails.Width -lt [int]$WBScreenModeDetails.Width) -or ([int]$PIScreenModeDetails.Height -lt [int]$WBScreenModeDetails.Height)){
                  #Write-debug "Pi Width: $($PIScreenModeDetails.Width) Pi Height: $($PIScreenModeDetails.Height) WB Width: $($WBScreenModeDetails.Width) WB Height: $($WBScreenModeDetails.Height)"
                  $Script:GUIActions.AvailableScreenModesWB | Where-Object {$_.RTG -eq $isRTG -and ([int]$_.Width -le [int]$PIScreenModeDetails.Width) -and ([int]$_.Height -le [int]$PIScreenModeDetails.Height)} | ForEach-Object {
                      $WPF_StartPage_ScreenModeWorkbench_Dropdown.AddChild($_.FriendlyName)
                  }
                   
                  $Script:GUIActions.ScreenModetoUseWB = ($Script:GUIActions.AvailableScreenModesWB | Where-Object {$_.RTG -eq $true} | Sort-Object {[int]$_.Height}, {[int]$_.Width}-Descending  | Where-Object {([int]$_.Width -le [int]$PIScreenModeDetails.Width) -and ([int]$_.Height -le [int]$PIScreenModeDetails.Height)} | Select-Object -First 1).FriendlyName                
    
                  $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem = $Script:GUIActions.ScreenModetoUseWB
                  $Script:GUIActions.ScreenModeWBColourDepth = ($Script:GUIActions.AvailableScreenModesWB | Where-Object {$_.FriendlyName -eq $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem}).DefaultDepth
                  $WPF_StartPage_WorkbenchColour_Slider.Value = $Script:GUIActions.ScreenModeWBColourDepth 
                  $WPF_StartPage_WorkbenchColour_Value.Text = (Get-NumberOfColours -ColourDepth $Script:GUIActions.ScreenModeWBColourDepth)     
                  
            }
            else {
                  $Script:GUIActions.AvailableScreenModesWB | Where-Object {$_.RTG -eq $isRTG -and ([int]$_.Width -le [int]$PIScreenModeDetails.Width) -and ([int]$_.Height -le [int]$PIScreenModeDetails.Height)} | ForEach-Object {
                      $WPF_StartPage_ScreenModeWorkbench_Dropdown.AddChild($_.FriendlyName)
                  }
                  $WPF_StartPage_ScreenModeWorkbench_Dropdown.SelectedItem = $Script:GUIActions.ScreenModetoUseWB            
            }
        }
    }

    $null = Update-UI -Emu68Settings

})