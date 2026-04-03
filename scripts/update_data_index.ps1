param()

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$dailyDir = Join-Path $repoRoot 'data\daily'
$indexPath = Join-Path $repoRoot 'data\index.json'

if (-not (Test-Path $dailyDir)) {
    $payload = @{ dailyFiles = @() }
    $payload | ConvertTo-Json -Depth 4 | Set-Content -Path $indexPath -Encoding UTF8
    exit 0
}

$files = Get-ChildItem -Path $dailyDir -Filter '*.md' | Sort-Object Name
$items = foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    [ordered]@{
        date = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        fileName = $file.Name
        path = "data/daily/$($file.Name)"
        hasQuestions = ($content -match '^###\s+\d+\s*$')
    }
}

$payload = [ordered]@{ dailyFiles = @($items) }
$payload | ConvertTo-Json -Depth 4 | Set-Content -Path $indexPath -Encoding UTF8
