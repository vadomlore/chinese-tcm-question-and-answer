param(
    [string]$TaskName = 'TCM-Daily-Card-Prepare',
    [string]$At = '12:00'
)

$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'prepare_daily_prompt.ps1'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At $At
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description 'Prepare daily TCM card task file at noon.' -Force | Out-Null

Write-Output "Registered task: $TaskName at $At"