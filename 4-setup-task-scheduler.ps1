# Setup scheduled task to run the updater script on startup

$scriptPath = "C:\Scripts\AppStream-AppUpdate.ps1"
$logPath = "C:\Logs\ApplicationUpdate.log"

if (-not (Test-Path (Split-Path $scriptPath))) {
    New-Item -ItemType Directory -Path (Split-Path $scriptPath) -Force
}
if (-not (Test-Path (Split-Path $logPath))) {
    New-Item -ItemType Directory -Path (Split-Path $logPath) -Force
}

$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger -AtStartup -Delay "00:05:00"
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew

$taskName = "AppStreamAppUpdater"
$taskDescription = "Updates applications on AppStream 2.0 Image Builder startup."

$task = New-ScheduledTask `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description $taskDescription

Register-ScheduledTask -TaskName $taskName -InputObject $task

# Optional verification
Get-ScheduledTask -TaskName $taskName | Select-Object TaskName,State,Triggers,Actions,Principal
Get-ScheduledTaskInfo -TaskName $taskName