<#
Updater.ps1 - Verifica atualizações nos Releases e aplica com confirmação do usuário
#>
param([switch]$Force)

# Força TLS 1.2 para compatibilidade com GitHub
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$AppDir = $PSScriptRoot
$ConfigPath = Join-Path $AppDir "config.json"
$VersionFile = Join-Path $AppDir "version.txt"
$BackupDir = Join-Path $AppDir "_backup"
$TempDir = Join-Path $env:TEMP "postech_update_tmp"
$TempZip = Join-Path $env:TEMP "postech_update.zip"
$Repo = "DyFuchs/Organizador_POSTECH"

function Write-Status { param($Msg, $Color="White"); Write-Host "[Updater] $Msg" -ForegroundColor $Color }

# 1. Verifica se AutoUpdate está ativado
$shouldCheck = $Force
if (-not $shouldCheck -and (Test-Path $ConfigPath)) {
    try {
        $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        $shouldCheck = [bool]$cfg.AutoUpdate
    } catch { $shouldCheck = $false }
}

if (-not $shouldCheck) {
    Write-Status "Atualizacao automatica desligada. Pulando verificacao." "Gray"
    return
}

# 2. Lê versão local
$localVer = "0.0.0"
if (Test-Path $VersionFile) { $localVer = (Get-Content $VersionFile -Raw).Trim() }

# 3. Consulta GitHub Releases
Write-Status "Verificando releases no GitHub..." "Gray"
try {
    $apiUrl = "https://api.github.com/repos/$Repo/releases"
    $releases = Invoke-RestMethod -Uri $apiUrl -TimeoutSec 15 -Headers @{"User-Agent"="POSTECH-Updater"} -ErrorAction Stop
    $latest = $releases | Where-Object { -not $_.draft -and -not $_.prerelease } | Select-Object -First 1
    
    if (-not $latest) { Write-Status "Nenhuma release publica encontrada." "Yellow"; return }
    
    $asset = $latest.assets | Where-Object { $_.name -like "*Organizador*.zip" -and $_.name -match '\d+\.\d+\.\d+' } | Select-Object -First 1
    if (-not $asset) { Write-Status "ZIP valido nao encontrado na release $($latest.tag_name)." "Yellow"; return }
    
    $remoteVer = if ($asset.name -match '(\d+\.\d+\.\d+)') { $Matches[1] } else { "unknown" }
} catch {
    Write-Status "Falha ao consultar GitHub: $($_.Exception.Message)" "Red"
    return
}

# 4. Compara versões
try {
    $isNewer = ([version]$remoteVer -gt [version]$localVer)
} catch {
    $isNewer = $false
}

if (-not $isNewer) {
    Write-Status "Aplicacao ja esta na versao mais recente (v$localVer)." "Green"
    return
}

# 5. Pergunta ao usuário
Write-Status "Nova versao disponivel: v$remoteVer (atual: v$localVer)" "Yellow"
$response = Read-Host "Deseja atualizar agora? [S/N]"
if ($response.ToUpper() -ne 'S') {
    Write-Status "Atualizacao cancelada pelo usuario." "Gray"
    return
}

Write-Status "Iniciando processo de atualizacao..." "Cyan"

# 6. Cria backup
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = Join-Path $BackupDir "backup_v${localVer}_$timestamp"
New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
$filesToBackup = @("script.ps1", "Updater.ps1", "config.json", "version.txt", "Launch.bat")
foreach ($f in $filesToBackup) {
    $src = Join-Path $AppDir $f
    if (Test-Path $src) { Copy-Item $src $backupPath -Force -ErrorAction SilentlyContinue }
}
Write-Status "Backup criado: $backupPath" "Green"

# 7. Download
try {
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $TempZip -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
} catch {
    Write-Status "Falha no download: $($_.Exception.Message)" "Red"
    return
}

# 8. Extração
try {
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
    New-Item -Path $TempDir -ItemType Directory -Force | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($TempZip, $TempDir)
} catch {
    Write-Status "Falha na extracao: $($_.Exception.Message)" "Red"
    return
}

# 9. Substituição de arquivos
try {
    $extractedScript = Get-ChildItem $TempDir -Filter "script.ps1" -Recurse -File | Select-Object -First 1
    if (-not $extractedScript) { throw "script.ps1 nao encontrado no pacote" }
    
    $sourceRoot = $extractedScript.DirectoryName
    Get-ChildItem $sourceRoot | ForEach-Object {
        Copy-Item $_.FullName $AppDir -Recurse -Force -ErrorAction Stop
    }
} catch {
    Write-Status "Falha ao aplicar atualizacao: $($_.Exception.Message)" "Red"
    return
}

# 10. Finalização
$remoteVer | Set-Content $VersionFile -Encoding UTF8 -Force
if (Test-Path $TempZip) { Remove-Item $TempZip -Force }
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }

Write-Status "Atualizacao aplicada com sucesso! Versao atual: v$remoteVer" "Green"
Write-Host ""
