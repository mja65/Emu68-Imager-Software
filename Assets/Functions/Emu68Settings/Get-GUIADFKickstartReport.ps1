function Get-GUIADFKickstartReport {
    param (
        $Text,
        $Title,
        $DatatoPopulate,
        $WindowWidth,
        $WindowHeight,
        $DataGridWidth,
        $DataGridHeight,
        $GridLinesVisibility,
        $FieldsSorted
    )
     
    # $Title = 'ADFs to be used'
    # $Text = 'The following ADFs will be used:'
    # $DatatoPopulate = $Script:AvailableADFs 
    # $WindowWidth =700 
    # $WindowHeight =350 
    # $DataGridWidth =570 
    # $DataGridHeight =200 
    # $GridLinesVisibility ='None' 
    # $FieldsSorted = ('Status','ADF Name','Path')

    $WPF_ADFKickstartReporting = Get-XAML -WPFPrefix 'WPF_ADFKickstartReporting_' -XMLFile '.\Assets\WPF\SetupEmu68\Window_ADFKickstartReporting.xaml' -ActionsPath '.\Assets\UIActions\StartPage\ADFKickstartReporting\' -AddWPFVariables

    $WPF_ADFKickstartReporting.Top=300
    $WPF_ADFKickstartReporting.Left=300

    If ($FieldsSorted){
        $Fields = $FieldsSorted
    }
    else{
        $Fields = (($DatatoPopulate | Get-Member -MemberType NoteProperty).Name)
    }


    $Datatable = New-Object System.Data.DataTable
    [void]$Datatable.Columns.AddRange($Fields)
    foreach ($line in $DatatoPopulate)
    {
        $Array = @()
        Foreach ($Field in $Fields)
        {
            $array += $line.$Field
        }
        [void]$Datatable.Rows.Add($array)
    }
    
    $WPF_ADFKickstartReporting_TextBox.Text = $Text
    
    $WPF_ADFKickstartReporting_Datagrid.ItemsSource = $Datatable.DefaultView
    if ($DataGridWidth){
        $WPF_ADFKickstartReporting_Datagrid.Width = "$DataGridWidth"
    }
    if($DataGridHeight){
        $WPF_ADFKickstartReporting_Datagrid.Height = "$DataGridHeight"
    }
    if($GridLinesVisibility){
        $WPF_ADFKickstartReporting_Datagrid.GridLinesVisibility = $GridLinesVisibility
    }
    
    if ($Title){
        $WPF_ADFKickstartReporting.Title = $Title
    }
    if ($WindowHeight){
        $WPF_ADFKickstartReporting.Height =$WindowHeight
    }
    if ($WindowWidth){
        $WPF_ADFKickstartReporting.Width = $WindowWidth
    }
    
    
    $WPF_ADFKickstartReporting.ShowDialog() | out-null

}