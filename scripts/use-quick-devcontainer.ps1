# Switch to Quick Dev Container (no setup - opens in ~1 min instead of 5-30 min)
# Use when "Cursor is setting up..." is stuck for hours.
# Run from project root.

$ErrorActionPreference = "Stop"
$root = if (Test-Path "pyproject.toml") { (Get-Location).Path } else { Split-Path -Parent $PSScriptRoot }
$dc = "$root\.devcontainer"
$main = "$dc\devcontainer.json"
$quick = "$dc\devcontainer-quick.json"
$bak = "$dc\devcontainer.json.full-backup"

if (-not (Test-Path $quick)) {
    Write-Host "Error: devcontainer-quick.json not found." -ForegroundColor Red
    exit 1
}
if (Test-Path $main) {
    Copy-Item $main $bak -Force
    Write-Host "Backed up devcontainer.json to devcontainer.json.full-backup" -ForegroundColor Yellow
}
Copy-Item $quick $main -Force
Write-Host "Switched to Quick Dev Container (no postCreateCommand)." -ForegroundColor Green
Write-Host "Now: Close Cursor, then Reopen in Container. It will open fast." -ForegroundColor Cyan
Write-Host "After it opens, run: poetry config virtualenvs.in-project true; poetry install" -ForegroundColor Cyan
