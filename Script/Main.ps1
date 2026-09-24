<#PSScriptInfo
.VERSION 2.2.1
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


Get-ChildItem -Path '.\Assets\Variables\' -File -Recurse | ForEach-Object {
    . ($_).fullname
}

Get-ChildItem -Path '.\Assets\Functions\' -File -Recurse | ForEach-Object {
    . ($_).fullname
}


if ((Get-Location).Path -match '[^a-zA-Z0-9\s\.\-_:\\]'){
    Write-ErrorMessage -Message "The path to the Emu68 Imager contains special characters which may cause issues with some of the tools used in the image creation process. Please move Emu68 Imager to a location that does not contain any special characters and try again." -Title "Invalid Path" -ShowPopup
    exit
}

$ErrorActionPreference = "Stop"
#$DebugPreference = 'SilentlyContinue'

#$DebugPreference = 'Continue'

if (($env:TERM_PROGRAM)  -or ($psISE)) {
    $Script:GUICurrentStatus.RunMode = "VisualCodeorISE"
}
else {
    $Script:GUICurrentStatus.RunMode = "CommandLine"
}

$Script:Settings.Version = [system.version]'2.2.1'

$Script:GUIActions.ScriptPath = (Split-Path -Path $PSScriptRoot -Parent)

Write-Emu68ImagerLog -start

Show-Disclaimer

$Script:Settings.TotalNumberofTasks = 4

$Script:Settings.CurrentTaskNumber = 1
$Script:Settings.CurrentTaskName = "Reading Emu68 Imager Configuration file"
Write-StartTaskMessage

Read-ConfigFile

Write-TaskCompleteMessage

$Script:Settings.CurrentTaskName = "Checking Prerequisites for Using Emu68 Imager"
Write-StartTaskMessage

Confirm-Prerequisites

Write-TaskCompleteMessage

$Script:Settings.CurrentTaskName = "Checking for any unrequired files and removing"
Write-StartTaskMessage

#Confirm-NoExtraAmigaFiles

Write-TaskCompleteMessage

$Script:Settings.CurrentTaskName = "Startup Checks"
Write-StartTaskMessage

$Script:Settings.TotalNumberofSubTasks = 3
$Script:Settings.CurrentSubTaskName = "Creating Default Folders"
$Script:Settings.CurrentSubTaskNumber = 1
Write-StartSubTaskMessage

Confirm-DefaultPaths 

Remove-TempFolderFiles

$Script:Settings.CurrentSubTaskName = "Creating Input Files"
$Script:Settings.CurrentSubTaskNumber = 2
Write-StartSubTaskMessage

If (-not (Get-InputFiles)){
    exit
}
    
$Script:Settings.CurrentSubTaskName = "Getting Startup Files"
$Script:Settings.CurrentSubTaskNumber = 3
Write-StartSubTaskMessage


if (-not (Get-StartupFiles)){
    exit
}

Write-TaskCompleteMessage

if ($Script:GUICurrentStatus.RunMode -eq 'CommandLine'){
    get-process -id $Pid | set-windowstate -State MINIMIZE -SuppressErrors
}

Write-InformationMessage -Message "Loading Emu68 Imager UI..." -NoLog 

Remove-Variable -Scope Script -Name 'WPF_*'
If ($Script:GUICurrentStatus.OperationMode -eq "Advanced"){
    $WPF_MainWindow = Get-XAML -WPFPrefix 'WPF_Window_' -XMLFile '.\Assets\WPF\Main_Window.xaml' -ActionsPath '.\Assets\UIActions\MainWindow\' -AddWPFVariables
}
elseif ($Script:GUICurrentStatus.OperationMode -eq "Simple"){
    $WPF_MainWindow = Get-XAML -WPFPrefix 'WPF_Window_' -XMLFile '.\Assets\WPF\Main_Window_Simple.xaml' -ActionsPath '.\Assets\UIActions\MainWindow\' -AddWPFVariables
}

$WPF_Window_Label_Title.Content = "Emu68 Imager v$([string]$Script:Settings.Version)" 

$VersionStatustoPopulate = Get-Emu68ImagerCurrentVersion -GithubRelease  $Script:Settings.Emu68GithubRepository 

$WPF_Window_Label_VersionStatus.Text  = $VersionStatustoPopulate.TexttoReport

if ($VersionStatustoPopulate.IsUptoDate -eq $true){
    $WPF_Window_VersionStatus_URL_TextBlock.Visibility = "hidden"
    $WPF_Window_Label_VersionStatus.Foreground= "Black"

}
else {
    $WPF_Window_VersionStatus_URL_TextBlock.Visibility = "visible"
     $WPF_Window_Label_VersionStatus.Foreground= "Red"
}


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

update-ui -MainWindowButtons -Emu68Settings

$WPF_MainWindow.ShowDialog() | out-null

if ($Script:GUICurrentStatus.ProcessImageConfirmedbyUser -eq $true){    
    Write-ImageCreation
}
else {
    Write-ErrorMessage -Message "User Quit Tool! Exiting!"
    exit
}

# Copy-Emu68Imager -NewLocation "E:\Emu 68 Imager Test Files" -compress -UserFiles

# # $WPF_MainWindow.Close()
# # [System.Windows.Controls.DataGrid].GetEvents() | Select-Object Name, *Method, EventHandlerType >test.txt

#$Script:GUIActions.AvailablePackages
