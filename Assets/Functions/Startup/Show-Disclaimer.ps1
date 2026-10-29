function Show-Disclaimer {
    param (
        $VersionStatus
    )

    #$VersionStatus = $VersionStatustoPopulate

    $WPF_Disclaimer = Get-XAML -WPFPrefix 'WPF_Disclaimer_' -XMLFile '.\Assets\WPF\Window_Disclaimer.xaml' -ActionsPath '.\Assets\UIActions\Disclaimer\' -AddWPFVariables
    $WPF_Disclaimer_TextBox_Header.Text = "Emu68 Imager v$($Script:Settings.Version)"

    If ($VersionStatus.IsUptoDate -eq $true){
        $WPF_Disclaimer_UpdateStatus.Text = $VersionStatus.TexttoReport
        $WPF_Disclaimer_UpdateStatus.Visibility = "Visible"
        $WPF_Disclaimer_UpdateBanner.Visibility = "Collapsed"
    }
    else {
        $WPF_Disclaimer_UpdateBanner.Visibility = "visible"
        $WPF_Disclaimer_UpdateStatus.Visibility = "hidden"
    }


    $null = $WPF_Disclaimer.ShowDialog()

    if (-not ($Script:GUICurrentStatus.OperationMode)){
        Write-ErrorMessage -Message "Exiting - Disclaimer Not Accepted"
        exit    
    }
}


