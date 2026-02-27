# OpenHands - Setup in-project .venv on Windows (equivalent to: make setup-venv)
# Creates .venv in the project folder so the IDE and Pyright can find the interpreter.
# Usage: Run from project root or from scripts folder:
#   powershell -ExecutionPolicy Bypass -File scripts/setup-venv-windows.ps1

$ErrorActionPreference = "Stop"

# Project root: same folder that contains pyproject.toml
$ProjectRoot = if (Test-Path "pyproject.toml") { (Get-Location).Path } else { Split-Path -Parent $PSScriptRoot }
if (-not (Test-Path "$ProjectRoot\pyproject.toml")) {
    Write-Host "Error: pyproject.toml not found. Run this script from the OpenHands project root or from the scripts folder." -ForegroundColor Red
    exit 1
}
Set-Location $ProjectRoot

Write-Host "Configuring Poetry to use in-project .venv..." -ForegroundColor Yellow
poetry config virtualenvs.in-project true

if (Test-Path ".venv") {
    Write-Host ".venv already exists. Run 'poetry install --with dev,test,runtime' to update dependencies." -ForegroundColor Green
} else {
    Write-Host "Removing cached venv so Poetry creates .venv in project..." -ForegroundColor Yellow
    poetry env remove --all 2>$null
    Write-Host "Creating .venv and installing dependencies..." -ForegroundColor Yellow
    # Use Python 3.12 if available (optional; Poetry will use default otherwise)
    $py312 = $null
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $ver = (python --version 2>&1) -replace "Python ", ""
        if ($ver -match "^3\.12") { $py312 = "python" }
    }
    if (-not $py312 -and (Test-Path "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe")) {
        $py312 = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
    }
    if ($py312) {
        poetry env use $py312
    }
    poetry install --with dev,test,runtime
    Write-Host "Python dependencies installed successfully." -ForegroundColor Green
}

Write-Host ""
Write-Host "In Cursor/VS Code: use Python: Select Interpreter and choose .venv\Scripts\python.exe" -ForegroundColor Cyan
