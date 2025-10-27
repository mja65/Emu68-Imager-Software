<#PSScriptInfo
.VERSION 2.0
.GUID 73d9401c-ab81-4be5-a2e5-9fc0834be0fc
.AUTHOR SupremeTurnip
.COMPANYNAME
.COPYRIGHT
.TAGS
.LICENSEURI https://github.com/mja65/Emu68-Imager/blob/main/LICENSE
.PROJECTURI https://github.com/mja65/Emu68-Imager
.ICONURI
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
.PRIVATEDATA
#>

<# 
.DESCRIPTION 
Script for Emu68Imager 
#> 

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Net.Http

#Set-Location -Path "C:\Users\Matt\OneDrive\Documents\DiskPartitioner"

Set-Location -Path (Split-Path -Path $PSScriptRoot -Parent)
[System.IO.Directory]::SetCurrentDirectory((Split-Path -Path $PSScriptRoot -Parent)) # Needed for Powershell 5 Compatibility

Get-ChildItem -Path '.\Assets\Variables\' -Recurse | Where-Object { $_.PSIsContainer -eq $false } | ForEach-Object {
    . ($_).fullname
}

Get-ChildItem -Path '.\Assets\Functions\' -Recurse | Where-Object { $_.PSIsContainer -eq $false } | ForEach-Object {
    . ($_).fullname
}

#$DebugPreference = 'SilentlyContinue'

#$DebugPreference = 'Continue'

if (($env:TERM_PROGRAM)  -or ($psISE)) {
    $Script:GUICurrentStatus.RunMode = "VisualCodeorISE"
}
else {
    $Script:GUICurrentStatus.RunMode = "CommandLine"
}

$Script:Settings.Version = [system.version]'2.0'

$Script:GUIActions.ScriptPath = (Split-Path -Path $PSScriptRoot -Parent)

Write-Emu68ImagerLog -start

Show-Disclaimer

$Script:Settings.TotalNumberofTasks = 2
$Script:Settings.CurrentTaskNumber = 1

$Script:Settings.CurrentTaskName = "Checking Prerequisites for Using Emu68 Imager"
Write-StartTaskMessage

Confirm-Prerequisites

Write-TaskCompleteMessage

$Script:Settings.CurrentTaskName = "Startup Checks"
Write-StartTaskMessage

$Script:Settings.TotalNumberofSubTasks = 3
$Script:Settings.CurrentSubTaskName = "Creating Default Folders"
$Script:Settings.CurrentSubTaskNumber = 1
Write-StartSubTaskMessage

Confirm-DefaultPaths 

$Script:Settings.CurrentSubTaskName = "Creating Input Files"
$Script:Settings.CurrentSubTaskNumber = 2
Write-StartSubTaskMessage

Get-InputFiles

$Script:Settings.CurrentSubTaskName = "Getting Startup Files"
$Script:Settings.CurrentSubTaskNumber = 3
Write-StartSubTaskMessage

if (-not (Get-StartupFiles)){
     exit
}

Write-TaskCompleteMessage

$Script:Settings.TotalNumberofTasks = 10

if ($Script:GUICurrentStatus.RunMode -eq 'CommandLine'){
    get-process -id $Pid | set-windowstate -State MINIMIZE
}

Remove-Variable -Scope Script -Name 'WPF_*'
If ($Script:GUICurrentStatus.OperationMode -eq "Advanced"){
    $WPF_MainWindow = Get-XAML -WPFPrefix 'WPF_Window_' -XMLFile '.\Assets\WPF\Main_Window.xaml' -ActionsPath '.\Assets\UIActions\MainWindow\' -AddWPFVariables
}
elseif ($Script:GUICurrentStatus.OperationMode -eq "Simple"){
    $WPF_MainWindow = Get-XAML -WPFPrefix 'WPF_Window_' -XMLFile '.\Assets\WPF\Main_Window_Simple.xaml' -ActionsPath '.\Assets\UIActions\MainWindow\' -AddWPFVariables
}

$WPF_Window_Label_Title.Content = "Emu68 Imager v$([string]$Script:Settings.Version)" 
$WPF_Window_Label_VersionStatus.Text = Get-Emu68ImagerCurrentVersion -GithubRelease "https://api.github.com/repos/mja65/Emu68Imager/releases" 

If ($Script:GUICurrentStatus.OperationMode -eq "Advanced"){
    $WPF_StartPage = Get-XAML -WPFPrefix 'WPF_StartPage_' -XMLFile '.\Assets\WPF\Grid_StartPageAdvancedMode.xaml' -ActionsPath '.\Assets\UIActions\StartPage\' -AddWPFVariables
}
elseif ($Script:GUICurrentStatus.OperationMode -eq "Simple"){
    $WPF_StartPage = Get-XAML -WPFPrefix 'WPF_StartPage_' -XMLFile '.\Assets\WPF\Grid_StartPageSimpleMode.xaml' -ActionsPath '.\Assets\UIActions\StartPage\' -AddWPFVariables
}
$WPF_Partition = Get-XAML -WPFPrefix 'WPF_DP_' -XMLFile '.\Assets\WPF\Grid_DiskPartition.xaml' -ActionsPath '.\Assets\UIActions\DiskPartition\' -AddWPFVariables

If ($Script:GUICurrentStatus.OperationMode -eq "Advanced"){
    $WPF_PackageSelection = Get-XAML -WPFPrefix 'WPF_PackageSelection_' -XMLFile '.\Assets\WPF\Grid_PackageSelection.xaml' -ActionsPath '.\Assets\UIActions\PackageSelection\' -AddWPFVariables
    Set-PartitionGridActions
}

$Script:GUICurrentStatus.ProcessImageStatus = $false

$WPF_Window_Main.AddChild($WPF_StartPage)
$Script:GUICurrentStatus.CurrentWindow = 'StartPage'

If ($Script:GUICurrentStatus.OperationMode -eq "Simple"){
    $WPF_Window_Button_LoadSettings.Visibility = "Hidden"
    $WPF_Window_Button_SaveSettings.Visibility = "Hidden"
    $WPF_Window_Button_PackageSelection.Visibility = "Hidden"
    $WPF_Window_LoadandSaveSettings_Label.Visibility = "Hidden"

}

update-ui -MainWindowButtons

$WPF_MainWindow.ShowDialog() | out-null

if ($Script:GUICurrentStatus.ProcessImageConfirmedbyUser -eq $true){    
    $Script:Settings.CurrentTaskNumber = 1
    Write-ImageCreation
}
else {
    Write-ErrorMessage -Message "User Quit Tool! Exiting!"
    exit
}

# # $WPF_MainWindow.Close()
# # [System.Windows.Controls.CheckBox].GetEvents() | Select-Object Name, *Method, EventHandlerType >test.txt
