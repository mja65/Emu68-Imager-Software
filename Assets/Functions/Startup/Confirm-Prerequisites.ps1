function Confirm-Prerequisites {
    param (
    )
    

    $Script:Settings.TotalNumberofSubTasks = 2
    $Script:Settings.CurrentSubTaskNumber = 1
    $Script:Settings.CurrentSubTaskName = "Initial checks"    
    
    Write-StartSubTaskMessage 
    
    
    $ArchitectureFound = Test-Architecture -Architecture ($Script:Settings.Architecture)
    $isAdministrator = Test-Administrator
    
    $null = Confirm-Scaling

    $FailedCheck = 0       

    if ($ArchitectureFound -eq "Other"){
        $FailedCheck ++
    }
    if ($isAdministrator  -eq $false){
        $FailedCheck ++
    }

    if ($FailedCheck -gt 0){
        $WPF_FailedPrerequisite = Get-XAML -WPFPrefix 'WPF_PreRequisiteCheck_' -XMLFile '.\Assets\WPF\Window_FailedPrerequisite.xaml' -ActionsPath '.\Assets\UIActions\PreRequisiteCheck\' -AddWPFVariables
        if (($ArchitectureFound -eq "Other") -and ($isAdministrator  -eq $false)){
            $WPF_PreRequisiteCheck_TextBox_Message.Text = 'You must run the tool in Administrator Mode and using a 64bit OS!'
        }
        elseif (($ArchitectureFound -eq "Other") -and ($isAdministrator  -eq $true)) {
            $WPF_PreRequisiteCheck_TextBox_Message.Text = 'You must run the tool using a 64bit OS!'
        }
        elseif ($isAdministrator  -eq $false)  {
            $WPF_PreRequisiteCheck_TextBox_Message.Text = 'You must run the tool in Administrator Mode!'
        }
        $null = $WPF_FailedPrerequisite.ShowDialog()
        exit
    }

    $Script:Settings.CurrentSubTaskNumber = 2
    $Script:Settings.CurrentSubTaskName = "Testing accessibility of servers"

    Write-StartSubTaskMessage

    $IsInternetAccessible = Test-AccesstoServers


      if ($IsInternetAccessible -eq $false){
          $WPF_FailedPrerequisite = Get-XAML -WPFPrefix 'WPF_PreRequisiteCheck_' -XMLFile '.\Assets\WPF\Window_FailedPrerequisite.xaml' -ActionsPath '.\Assets\UIActions\PreRequisiteCheck\' -AddWPFVariables
          $WPF_PreRequisiteCheck_TextBox_Message.Text = 'You do not have access to the servers needed to set up the Image! Check internet connectivity and/or your computer security settings!'
          $null = $WPF_FailedPrerequisite.ShowDialog()
          exit        
      }  
          
}

