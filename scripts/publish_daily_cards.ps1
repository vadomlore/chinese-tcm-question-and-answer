param(
    [string]$Date = (Get-Date).ToString('yyyy-MM-dd'),
    [string]$CommitMessage
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$targetFile = Join-Path $repoRoot "data\daily\$Date.md"

if (-not (Test-Path $targetFile)) {
    throw "Daily file not found: $targetFile"
}

if (-not $CommitMessage) {
    $CommitMessage = "Add TCM daily cards for $Date"
}

& (Join-Path $PSScriptRoot 'update_data_index.ps1')

Push-Location $repoRoot
try {
    git add -- "data/daily/$Date.md" "data/index.json" "prompts/daily/today-task.md" "index.html" "static" ".nojekyll" | Out-Null
    git commit -m $CommitMessage
    git push
}
finally {
    Pop-Location
}