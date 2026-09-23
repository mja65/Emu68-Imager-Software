function Show-SpinnerWhileDeleting {
    param (
        [scriptblock]$ScriptBlock,
        [int]$Delay = 100,
        [string]$Message = "Deleting files"
    )

    $spinner = @('|', '/', '-', '\')
    $index = 0
    $job = Start-Job -ScriptBlock $ScriptBlock

    while ($job.State -eq 'Running') {
        Write-Host -NoNewline "`r$($spinner[$index % $spinner.Length]) $Message..."
        Start-Sleep -Milliseconds $Delay
        $index++
    }

    try {
        Receive-Job $job -ErrorAction Stop | Out-Null
        Write-InformationMessage -Message "$Message complete." -NewLineBefore
    } catch {
        Write-InformationMessage -Message "$Message failed: $_" -NewLineBefore
    } finally {
        Remove-Job $job
    }
}
