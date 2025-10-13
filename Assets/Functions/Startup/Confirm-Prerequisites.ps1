function Confirm-Prerequisites {
    param (
    )
    
    $is64bit = Test-64bit
    $isAdministrator = Test-Administrator
    $FailedCheck = 0
        
    if ($is64bit -eq $false){
        $FailedCheck ++
    }
    if ($isAdministrator  -eq $false){
        $FailedCheck ++
    }
    
    if ($FailedCheck -gt 0){
        $WPF_FailedPrerequisite = Get-XAML -WPFPrefix 'WPF_PreRequisiteCheck_' -XMLFile '.\Assets\WPF\Window_FailedPrerequisite.xaml' -ActionsPath '.\Assets\UIActions\PreRequisiteCheck\' -AddWPFVariables
        if (($is64bit -eq $false) -and ($isAdministrator  -eq $false)){
            $WPF_PreRequisiteCheck_TextBox_Message.Text = 'You must run the tool in Administrator Mode and using a 64bit OS!'
        }
        elseif (($is64bit -eq $false) -and ($isAdministrator  -eq $true)) {
            $WPF_PreRequisiteCheck_TextBox_Message.Text = 'You must run the tool using a 64bit OS!'
        }
        elseif (($isAdministrator  -eq $false) -and ($is64bit -eq $true))  {
            $WPF_PreRequisiteCheck_TextBox_Message.Text = 'You must run the tool in Administrator Mode!'
        }
        $null = $WPF_FailedPrerequisite.ShowDialog()
        exit
    }

}

