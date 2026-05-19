@echo off
setlocal
cd /d "%~dp0"
set "SCRIPT=%~n0.ps1"

if not exist "%SCRIPT%" (
    echo Erro: "%SCRIPT%" nao encontrado na mesma pasta.
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT%"
pause