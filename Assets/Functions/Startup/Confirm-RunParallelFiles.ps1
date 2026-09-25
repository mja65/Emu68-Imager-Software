function Confirm-RunParallelFiles {
    param (
       
    )
       
$Msg_Header = @"
Parallel Downloading of Packages from the Internet
"@

$Msg_Body = @"
If you wish to use parallel downloading of packages from the internet, select "Yes" and NuGet (Package provider for Powershell) and ThreadJob (Powershell module for running parallel jobs) will be installed if not already present.
Select "No" and packages will be downloaded sequentially. Select "Never Again" to not be asked again.
"@

    $NeedsNuGet = -not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction Ignore)
    $NeedsThreadJob = -not (Get-Module -Name ThreadJob -ListAvailable)

    if (-not $NeedsNuGet -and -not $NeedsThreadJob) {
        return "Yes"
    }

    $UserChoice = Show-DecisionBox -Msg_Body $Msg_Body -Msg_Header $Msg_Header

    if ($UserChoice -ne "Yes") {
        return $UserChoice
    }
    
    if ($NeedsNuGet) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
        $NeedsNuGet = -not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction Ignore)
        if ($NeedsNuGet){
            Write-ErrorMessage -Message "Could not install NuGet! Either rerun and try again, consult the documentation for manual install steps, or select the option for sequential packages."
            Exit
        }
    }
    
    if ($NeedsThreadJob) {
        Install-Module -Name ThreadJob -Scope CurrentUser -Force -AllowClobber
        $NeedsThreadJob = -not (Get-Module -Name ThreadJob -ListAvailable)
        If ($NeedsThreadJob){
            Write-ErrorMessage -Message "Could not install ThreadJob! Either rerun and try again, consult the documentation for manual install steps, or select the option for sequential packages."
            Exit                
        }

    }

    return "Yes"
    
}
