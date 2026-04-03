param(
    [string]$Date = (Get-Date).ToString('yyyy-MM-dd'),
    [string]$FocusTopics = 'jingluo,fangji,bianzheng',
    [int]$QuestionCount = 6,
    [switch]$OpenVSCode
)
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$dailyDir = Join-Path $repoRoot 'data\daily'
$promptDir = Join-Path $repoRoot 'prompts\daily'

if (-not (Test-Path $dailyDir)) {
    New-Item -ItemType Directory -Path $dailyDir | Out-Null
}

if (-not (Test-Path $promptDir)) {
    New-Item -ItemType Directory -Path $promptDir | Out-Null
}

$targetFile = Join-Path $dailyDir "$Date.md"
$yesterday = ([datetime]::ParseExact($Date, 'yyyy-MM-dd', $null)).AddDays(-1).ToString('yyyy-MM-dd')
$yesterdayFile = Join-Path $dailyDir "$yesterday.md"
$yesterdayRelative = if (Test-Path $yesterdayFile) { "data/daily/$yesterday.md" } else { 'none' }

if (-not (Test-Path $targetFile)) {
    $template = @"
# $Date TCM Daily Questions

- Date: $Date
- QuestionCount: $QuestionCount
- FocusTopics: $FocusTopics
- YesterdayFile: $yesterdayRelative
- GenerationMode: Copilot Chat slash prompt

## Daily Context
- This file is prepared at noon by a Windows scheduled task.
- Keep the questions short and suitable for commute review.
- If you want extra focus, add one short sentence in chat before generation.

## Daily Questions (AI Generated)
> Waiting for generation

## Notes
- After generation, you can make small edits and then run the publish script.
"@
    Set-Content -Path $targetFile -Value $template -Encoding UTF8
}
else {
    $existing = Get-Content -Path $targetFile -Raw
    $existing = [regex]::Replace($existing, '^- Date: .*$', "- Date: $Date", 'Multiline')
    $existing = [regex]::Replace($existing, '^- QuestionCount: .*$', "- QuestionCount: $QuestionCount", 'Multiline')
    $existing = [regex]::Replace($existing, '^- FocusTopics: .*$', "- FocusTopics: $FocusTopics", 'Multiline')
    $existing = [regex]::Replace($existing, '^- YesterdayFile: .*$', "- YesterdayFile: $yesterdayRelative", 'Multiline')
    Set-Content -Path $targetFile -Value $existing -Encoding UTF8
}

$todayTask = @"
date: $Date
targetFile: data/daily/$Date.md
yesterdayFile: $yesterdayRelative
focusTopics: $FocusTopics
questionCount: $QuestionCount

extraRequirements:
- default to short question and short answer
- optimize for commute review
- avoid strong overlap with yesterday if yesterday exists
- if the user adds a topic in chat, prefer the user's topic
"@

Set-Content -Path (Join-Path $promptDir 'today-task.md') -Value $todayTask -Encoding UTF8
Set-Content -Path (Join-Path $promptDir "$Date-task.md") -Value $todayTask -Encoding UTF8

& (Join-Path $PSScriptRoot 'update_data_index.ps1')

if ($OpenVSCode) {
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        & $codeCmd.Source $repoRoot (Join-Path $promptDir 'today-task.md') | Out-Null
    }
}

Write-Output "Prepared daily task for $Date"