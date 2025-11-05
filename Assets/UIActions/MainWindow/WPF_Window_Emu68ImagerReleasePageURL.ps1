$WPF_Window_Emu68ImagerReleasePageURL.add_RequestNavigate({
    param($sender, $e)
    Start-Process $e.Uri.AbsoluteUri
    $e.Handled = $true
})
