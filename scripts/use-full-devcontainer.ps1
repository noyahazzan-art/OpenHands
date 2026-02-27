# Restore Full Dev Container (with automatic setup)
# Run from project root.

$ErrorActionPreference = "Stop"
$root = if (Test-Path "pyproject.toml") { (Get-Location).Path } else { Split-Path -Parent $PSScriptRoot }
$dc = "$root\.devcontainer"
$main = "$dc\devcontainer.json"
$bak = "$dc\devcontainer.json.full-backup"

if (-not (Test-Path $bak)) {
    Write-Host "No backup found. The full config is in .devcontainer/setup.sh - devcontainer.json uses it via postCreateCommand." -ForegroundColor Yellow
    Write-Host "To restore, ensure devcontainer.json contains: `"postCreateCommand\": \".devcontainer/setup.sh`"" -ForegroundColor Yellow
    exit 0
}
Copy-Item $bak $main -Force
Remove-Item $bak -Force
Write-Host "Restored full Dev Container config." -ForegroundColor Green
Write-Host "Rebuild container to run full setup again." -ForegroundColor Cyan
