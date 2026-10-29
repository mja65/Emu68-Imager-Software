function Get-VisualBrushDefaultPartition {
    param (

        $Colour
    )
    
    #Write-host "Colour for visualbrush: $Colour"
    
    $canvas = [System.Windows.Controls.Canvas]::new()
    $rect = [System.Windows.Shapes.Rectangle]::new()
    $rect.Width = 10
    $rect.Height = 10
    $rect.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Colour)
    [void]$canvas.Children.Add($rect)
    
    $path1 = [System.Windows.Shapes.Path]::new()
    $path1.Stroke = [System.Windows.Media.Brushes]::White
    $path1.StrokeThickness = 0.5
    $path1.Data = [System.Windows.Media.Geometry]::Parse("M 0 0 l 10 10")
    [void]$canvas.Children.Add($path1)
    
    $path2 = [System.Windows.Shapes.Path]::new()
    $path2.Stroke = [System.Windows.Media.Brushes]::White
    $path2.StrokeThickness = 0.5
    $path2.Data = [System.Windows.Media.Geometry]::Parse("M 0 10 l 10 -10")
    [void]$canvas.Children.Add($path2)
    
    # 2. Create the VisualBrush and assign the viewport/tile configurations
    $visualBrush = [System.Windows.Media.VisualBrush]::new()
    $visualBrush.Visual = $canvas
    $visualBrush.TileMode = [System.Windows.Media.TileMode]::Tile
    $visualBrush.Viewport = [System.Windows.Rect]::new(0, 0, 10, 10)
    $visualBrush.ViewportUnits = [System.Windows.Media.BrushMappingMode]::Absolute
    $visualBrush.Viewbox = [System.Windows.Rect]::new(0, 0, 10, 10)
    $visualBrush.ViewboxUnits = [System.Windows.Media.BrushMappingMode]::Absolute

    return $visualBrush

}

