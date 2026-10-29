function Get-MouseCoordinatesRelativetoWindow {
    param (


    )

    $MicrosoftWindowThicknessHorizontal = 8
    $MicrosoftWindowTitle = 31

    $GUICoordinates = [PSCustomObject]@{
        MousePositionX = $null
        MousePositionY = $null
        MousePositionRelativetoWindowX = $null
        MousePositionRelativetoWindowY = $null
        MouseButtons = $null
    }

    $GUICoordinates.MousePositionX =  (([System.Windows.Forms.Cursor]::position).x)
    $GUICoordinates.MousePositionY =  (([System.Windows.Forms.Cursor]::position).y)
    $GUICoordinates.MousePositionRelativetoWindowX =  $GUICoordinates.MousePositionX - $WPF_MainWindow.Left - $MicrosoftWindowThicknessHorizontal 
    $GUICoordinates.MousePositionRelativetoWindowY =  $GUICoordinates.MousePositionY - $WPF_MainWindow.Top - $MicrosoftWindowTitle 
    $GUICoordinates.MouseButtons = ([System.Windows.Forms.UserControl]::MouseButtons)
    return $GUICoordinates
}
