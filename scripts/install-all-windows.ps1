# OpenHands - התקנת כל הדרישות ב-Windows
# הרץ כמן administrator: לחיצה ימנית -> "Run with PowerShell as Administrator"

$ErrorActionPreference = "Stop"
Write-Host "=== OpenHands - התקנת סביבה ===" -ForegroundColor Cyan

# 1. WSL2 + Ubuntu (נדרש ל-Docker)
Write-Host "`n[1/3] בודק WSL..." -ForegroundColor Yellow
if ((wsl -l -v 2>$null) -match "Ubuntu") {
    Write-Host "  Ubuntu כבר מותקן ב-WSL." -ForegroundColor Green
} else {
    Write-Host "  מתקין WSL ו-Ubuntu (יכול לקחת כמה דקות)..." -ForegroundColor Yellow
    wsl --install -d Ubuntu --no-launch
    Write-Host "  ייתכן שתצטרך להפעיל מחדש את המחשב. אחרי ההפעלה, הרץ שוב את הסקריפט." -ForegroundColor Yellow
    exit 0
}

# 2. Docker Desktop
Write-Host "`n[2/3] בודק Docker..." -ForegroundColor Yellow
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "  Docker כבר מותקן." -ForegroundColor Green
} else {
    Write-Host "  מתקין Docker Desktop דרך winget..." -ForegroundColor Yellow
    winget install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
    Write-Host "  אם הופיע חלון התקנה - אשר אותו. בסיום הפעל מחדש את המחשב." -ForegroundColor Yellow
    exit 0
}

# 3. תלויות הפרויקט (Python/Frontend - כבר הותקנו קודם)
Write-Host "`n[3/3] בודק תלויות הפרויקט..." -ForegroundColor Yellow
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

if (Get-Command poetry -ErrorAction SilentlyContinue) {
    Write-Host "  Poetry מותקן. אם תרצה להתקין מחדש תלויות Python: poetry install --with dev,test,runtime" -ForegroundColor Gray
}
if (Test-Path "frontend\package.json") {
    Write-Host "  Frontend קיים. אם תרצה להתקין מחדש: cd frontend && npm install && npm run build" -ForegroundColor Gray
}

Write-Host "`n=== סיום ===" -ForegroundColor Green
Write-Host "אם Docker הותקן עכשיו: הפעל מחדש את המחשב, פתח Docker Desktop, ואז ב-VS Code בחר Reopen in Container." -ForegroundColor Cyan
