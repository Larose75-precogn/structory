# PreCogn - Script de déploiement automatique
# À exécuter depuis le dossier du projet sur Windows

$ErrorActionPreference = "Stop"

Write-Host "=== PreCogn Deploy ===" -ForegroundColor Green

# 1. Vérifier Godot
$godotPath = Get-Command godot -ErrorAction SilentlyContinue
if (-not $godotPath) {
    Write-Host "ERROR: Godot not found in PATH" -ForegroundColor Red
    Write-Host "Install Godot 4.7 and add it to PATH, or modify this script"
    exit 1
}

Write-Host "Using Godot: $($godotPath.Source)" -ForegroundColor Cyan

# 2. Exporter
Write-Host "`nExporting for Web..." -ForegroundColor Yellow
godot --headless --export-release "Web"

if (-not (Test-Path "export\web\index.html")) {
    Write-Host "ERROR: Export failed" -ForegroundColor Red
    exit 1
}

Write-Host "Export successful!" -ForegroundColor Green

# 3. Copier vers Worker
Write-Host "`nCopying to Worker..." -ForegroundColor Yellow
if (-not (Test-Path "worker\public")) {
    New-Item -ItemType Directory -Path "worker\public" | Out-Null
}

Copy-Item -Path "export\web\*" -Destination "worker\public\" -Recurse -Force

Write-Host "Files copied to worker/public/" -ForegroundColor Green

# 4. Installer dépendances
Write-Host "`nInstalling dependencies..." -ForegroundColor Yellow
Set-Location worker
npm install

# 5. Vérifier authentification
Write-Host "`nChecking Cloudflare authentication..." -ForegroundColor Yellow
$wranglerWhoami = npx wrangler whoami 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nAuthentication required. Opening browser..." -ForegroundColor Yellow
    npx wrangler login
}

# 6. Déployer
Write-Host "`nDeploying to Cloudflare..." -ForegroundColor Yellow
npx wrangler deploy

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n=== Deployment successful! ===" -ForegroundColor Green
    Write-Host "Visit: https://precogn.org" -ForegroundColor Cyan
} else {
    Write-Host "`nDeployment failed" -ForegroundColor Red
    exit 1
}

Set-Location ..
