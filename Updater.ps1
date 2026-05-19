# Updater.ps1 - Versão Dinâmica Simplificada
param([switch]$Force)

param([switch]$Force)

# === AUTO-VERIFICAÇÃO DE CONFIGURAÇÃO ===
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$ShouldUpdate = $Force

if (-not $ShouldUpdate -and (Test-Path $ConfigPath)) {
    try {
        $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        if ($cfg.PSObject.Properties.Name -contains 'AutoUpdate') {
            $ShouldUpdate = [bool]$cfg.AutoUpdate
        }
    } catch { $ShouldUpdate = $false }
}

if (-not $ShouldUpdate) {
    Write-Host "[Updater] AutoUpdate desativado nas configuracoes. Pulando verificacao." -ForegroundColor Gray
    return
}
Write-Host "[Updater] AutoUpdate ATIVO. Buscando atualizacoes..." -ForegroundColor Cyan
# ==========================================

$Repo = "DyFuchs/Organizador_POSTECH"
$MainScript = "script.ps1"
$VersionFile = "version.txt"
$LocalVer = if (Test-Path $VersionFile) { (Get-Content $VersionFile).Trim() } else { "0.0.0" }

Write-Host "[Updater] Local: $LocalVer" -ForegroundColor Cyan

try {
    # Busca todas as releases publicadas
    $releases = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases" -TimeoutSec 15 -Headers @{"User-Agent"="Updater"}
    
    # Filtra apenas published (não draft/pre-release) e ordena por data
    $release = $releases | Where-Object { -not $_.draft -and -not $_.prerelease } | Sort-Object { $_.published_at } -Descending | Select-Object -First 1
    
    if (-not $release) { 
        Write-Host "[Updater] No published release found" -ForegroundColor Red
        return 
    }
    
    # Busca ZIP que contenha "Organizador" e tenha versão no nome
    $asset = $release.assets | Where-Object { 
        $_.name -like "*Organizador*.zip" -and $_.name -match '\d+\.\d+\.\d+' 
    } | Select-Object -First 1
    
    if (-not $asset) { 
        Write-Host "[Updater] No valid ZIP found. Available assets:" -ForegroundColor Red
        $release.assets | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor Yellow }
        return 
    }
    
    # Extrai versão do nome do arquivo
    $RemoteVer = if ($asset.name -match '(\d+\.\d+\.\d+)') { $Matches[1] } else { "unknown" }
    
    Write-Host "[Updater] Remote: $RemoteVer ($($asset.name))" -ForegroundColor Cyan
    
    # Compara versões
    if (-not $Force -and $RemoteVer -le $LocalVer) {
        Write-Host "[Updater] Already up to date" -ForegroundColor Green
        return
    }
    
    Write-Host "[Updater] Downloading..." -ForegroundColor Yellow
    Invoke-WebRequest $asset.browser_download_url -OutFile "update.zip" -UseBasicParsing -TimeoutSec 60
    
    Write-Host "[Updater] Extracting..." -ForegroundColor Yellow
    if (Test-Path "_tmp") { Remove-Item "_tmp" -Recurse -Force }
    New-Item "_tmp" -ItemType Directory -Force | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory("update.zip", "_tmp")
    
    $found = Get-ChildItem "_tmp" -Filter $MainScript -Recurse -File | Select-Object -First 1
    if (-not $found) { 
        Write-Host "[Updater] script.ps1 not found in ZIP" -ForegroundColor Red
        Remove-Item "update.zip" -Force
        Remove-Item "_tmp" -Recurse -Force
        return 
    }
    
    # Backup
    if (Test-Path $MainScript) {
        if (-not (Test-Path "_backup")) { New-Item "_backup" -ItemType Directory -Force | Out-Null }
        Copy-Item $MainScript "_backup\script_$LocalVer.ps1" -Force
    }
    
    # Substitui
    Copy-Item $found.FullName $MainScript -Force
    if ($RemoteVer -ne "unknown") { $RemoteVer | Set-Content $VersionFile -Encoding UTF8 }
    
    # Limpa
    Remove-Item "update.zip" -Force
    Remove-Item "_tmp" -Recurse -Force
    
    Write-Host "[Updater] Updated to $RemoteVer!" -ForegroundColor Green
    Write-Host "Press Enter to start..." -ForegroundColor Yellow
    Read-Host | Out-Null
    
} catch {
    Write-Host "[Updater] Error: $($_.Exception.Message)" -ForegroundColor Red
}
