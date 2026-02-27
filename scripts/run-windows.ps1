# OpenHands - Run script for Windows
# Starts backend and frontend. Requires: Poetry, Node.js, frontend built (npm run build)

param(
    [string]$BackendHost = "127.0.0.1",
    [int]$BackendPort = 3000,
    [string]$FrontendHost = "127.0.0.1",
    [int]$FrontendPort = 3001
)

$ErrorActionPreference = "Stop"
$BackendHostPort = "${BackendHost}:${BackendPort}"

# Ensure we're in project root
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path "$ProjectRoot\pyproject.toml")) {
    $ProjectRoot = (Get-Location).Path
}
Set-Location $ProjectRoot

# Check frontend build
if (-not (Test-Path "frontend\build\index.html")) {
    Write-Host "Frontend build not found. Run: cd frontend && npm run build" -ForegroundColor Red
    exit 1
}

# Create logs dir
New-Item -ItemType Directory -Force -Path "logs" | Out-Null

# Start backend in background
Write-Host "Starting backend server..." -ForegroundColor Yellow
$backendJob = Start-Job -ScriptBlock {
    param($backendHostParam, $backendPortParam)
    Set-Location $using:ProjectRoot
    poetry run uvicorn openhands.server.listen:app --host $backendHostParam --port $backendPortParam
} -ArgumentList $BackendHost, $BackendPort

# Wait for backend to be ready
Write-Host "Waiting for backend to start..." -ForegroundColor Yellow
$maxAttempts = 60
$attempt = 0
$ready = $false
while ($attempt -lt $maxAttempts) {
    try {
        $response = Invoke-WebRequest -Uri "http://${BackendHost}:${BackendPort}/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $ready = $true
            break
        }
    } catch {
        # Backend might not have /api/health - try root
        try {
            $null = Invoke-WebRequest -Uri "http://${BackendHost}:${BackendPort}/" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
            $ready = $true
            break
        } catch {}
    }
    Start-Sleep -Milliseconds 500
    $attempt++
}
if (-not $ready) {
    Stop-Job $backendJob
    Remove-Job $backendJob
    Write-Host "Backend failed to start within 30 seconds." -ForegroundColor Red
    exit 1
}
Write-Host "Backend started successfully." -ForegroundColor Green

# Start frontend (foreground - blocks)
Write-Host "Starting frontend..." -ForegroundColor Yellow
$env:VITE_BACKEND_HOST = $BackendHostPort
$env:VITE_FRONTEND_PORT = $FrontendPort
Push-Location frontend
try {
    npm run dev -- --port $FrontendPort --host $FrontendHost
} finally {
    Pop-Location
    Stop-Job $backendJob -ErrorAction SilentlyContinue
    Remove-Job $backendJob -ErrorAction SilentlyContinue
}
