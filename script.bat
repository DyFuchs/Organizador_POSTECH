@echo off
setlocal
cd /d "%~dp0"

:: Fix de encoding para console
chcp 65001 >nul 2>&1

:: Verifica se PowerShell está disponível
where powershell.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRO] PowerShell nao encontrado. Instale o PowerShell 5.1 ou superior.
    pause
    exit /b 1
)

:: Executa o updater primeiro
echo [Launcher] Verificando atualizacoes...
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0Updater.ps1"

:: Lança a aplicação principal
echo [Launcher] Iniciando Organizador de Pastas POSTECH...
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0script.ps1"

:: Mantém janela aberta se executado diretamente
if /i "%~1"=="" pause
