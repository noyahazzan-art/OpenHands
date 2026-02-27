# OpenHands - Windows remediation script
# Addresses: Secure Boot (1801), DCOM (10010)
# Run as Administrator for full remediation

param(
    [switch]$SecureBoot,
    [switch]$DCOM,
    [switch]$All
)

$ErrorActionPreference = "Continue"

if (-not ($SecureBoot -or $DCOM -or $All)) {
    Write-Host "Usage: .\scripts\fix-windows-issues.ps1 [-SecureBoot] [-DCOM] [-All]" -ForegroundColor Cyan
    Write-Host "  -SecureBoot  Open Secure Boot certificate update page" -ForegroundColor Gray
    Write-Host "  -DCOM        Apply DCOM 10010 remediation (services)" -ForegroundColor Gray
    Write-Host "  -All         Run both (default)" -ForegroundColor Gray
    Write-Host ""
    $All = $true
}

# Secure Boot (1801) - Open Microsoft guidance page
function Invoke-SecureBootFix {
    Write-Host "`n[Secure Boot 1801] Opening Microsoft certificate update page..." -ForegroundColor Yellow
    $url = "https://go.microsoft.com/fwlink/?linkid=2301018"
    try {
        Start-Process $url
        Write-Host "  Browser opened. Follow the guidance for your device type." -ForegroundColor Green
        Write-Host "  Typical actions: Windows Update, OEM firmware update, or UEFI update." -ForegroundColor Gray
    } catch {
        Write-Host "  Failed to open: $url" -ForegroundColor Red
    }
}

# DCOM (10010) - Enable Function Discovery Resource Publication, check services
function Invoke-DCOMFix {
    Write-Host "`n[DCOM 10010] Applying remediation..." -ForegroundColor Yellow

    # Check if running as admin (needed for service changes)
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "  Run as Administrator for service changes. Attempting what's possible..." -ForegroundColor Yellow
    }

    # Function Discovery Resource Publication - common fix for DCOM 10010
    $serviceName = "FDResPub"
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.StartType -eq "Disabled") {
            if ($isAdmin) {
                try {
                    Set-Service -Name $serviceName -StartupType Manual -ErrorAction Stop
                    Write-Host "  Set $serviceName to Manual startup." -ForegroundColor Green
                } catch {
                    $err = $_.Exception.Message
                    Write-Host "  Could not change ${serviceName} (need Admin). $err" -ForegroundColor Red
                }
            } else {
                Write-Host "  $serviceName is Disabled. Run as Admin to set Manual." -ForegroundColor Yellow
            }
        }
        if ($service.Status -ne "Running" -and $isAdmin) {
            try {
                Start-Service -Name $serviceName -ErrorAction Stop
                Write-Host "  Started $serviceName." -ForegroundColor Green
            } catch {
                $err = $_.Exception.Message
                Write-Host "  Could not start ${serviceName}. $err" -ForegroundColor Red
            }
        } elseif ($service.Status -eq "Running") {
            Write-Host "  $serviceName is already running." -ForegroundColor Green
        }
    } else {
        Write-Host "  $serviceName not found (may not apply to this SKU)." -ForegroundColor Gray
    }

    Write-Host "  If DCOM errors persist: Settings > Gaming > Xbox Game Bar - disable if unused." -ForegroundColor Gray
}

# Run selected fixes
if ($SecureBoot -or $All) { Invoke-SecureBootFix }
if ($DCOM -or $All) { Invoke-DCOMFix }

Write-Host "`nDone." -ForegroundColor Cyan
