@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1

:: ==============================================================================
:: CONFIGURACAO
:: ==============================================================================
set "REPO=DyFuchs/Organizador_POSTECH"
set "BRANCH=main"

:: LOGICA DE DIRETORIO PADRAO
:: %~1 remove as aspas do primeiro argumento se elas existirem
if "%~1"=="" (
    set "DEFAULT_DIR=%~dp0"
) else (
    set "DEFAULT_DIR=%~1"
)

:: Limpeza de segurança: Remove aspas redundantes e barra final
set "DEFAULT_DIR=%DEFAULT_DIR:"=%"
if "%DEFAULT_DIR:~-1%"=="\" set "DEFAULT_DIR=%DEFAULT_DIR:~0,-1%"

:: ==============================================================================
:: INTERFACE
:: ==============================================================================
echo ========================================
echo    ORGANIZADOR POSTECH - INSTALADOR
echo ========================================
echo.

:: VERIFICAR POWERSHELL
where powershell.exe >nul 2>&1
if errorlevel 1 (
    echo [ERRO] PowerShell nao encontrado.
    pause
    exit /b 1
)

:: VERIFICAR CURL
where curl.exe >nul 2>&1
if errorlevel 1 (
    set "USE_CURL=0"
) else (
    set "USE_CURL=1"
)

:: ==============================================================================
:: ESCOLHA DO DIRETORIO
:: ==============================================================================
echo [PASSO 1] Definindo local de instalacao...
echo.
echo    Sugerido: %DEFAULT_DIR%
set /p "INSTALL_DIR=    Digite o caminho ou aperte Enter para aceitar: "

if "%INSTALL_DIR%"=="" (
    set "INSTALL_DIR=%DEFAULT_DIR%"
)

:: Limpeza de aspas e barras do input do usuario
set "INSTALL_DIR=%INSTALL_DIR:"=%"
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

:: Valida caracteres proibidos
echo %INSTALL_DIR% | findstr /r "[<>|?*]" >nul
if !errorlevel! equ 0 (
    echo.
    echo [ERRO] O caminho contem caracteres invalidos.
    pause
    exit /b 1
)

:: Verificar se pasta ja existe
if exist "%INSTALL_DIR%" (
    echo.
    echo [AVISO] A pasta ja existe.
    set /p "CONF=    Deseja substituir os arquivos? [S/N]: "
    if /i not "!CONF!"=="S" (
        echo Instalacao cancelada.
        pause
        exit /b 0
    )
)

:: Criar pasta de instalacao (com aspas para suportar espaços)
mkdir "%INSTALL_DIR%" 2>nul

:: ==============================================================================
:: DOWNLOAD E INSTALACAO
:: ==============================================================================
echo.
echo [PASSO 2] Baixando arquivos do GitHub...

set "FILES=script.ps1 Updater.ps1 config.json version.txt"

for %%F in (%FILES%) do (
    echo    - Baixando %%F... -NoNewline
    if "!USE_CURL!"=="1" (
        curl -L -s -o "%INSTALL_DIR%\%%F" "https://raw.githubusercontent.com/%REPO%/%BRANCH%/%%F"
    ) else (
        powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/%REPO%/%BRANCH%/%%F' -OutFile '%INSTALL_DIR%\%%F' -UseBasicParsing"
    )
    if exist "%INSTALL_DIR%\%%F" (
        echo [OK]
    ) else (
        echo [ERRO]
    )
)

:: Verificar se arquivo principal foi baixado
if not exist "%INSTALL_DIR%\script.ps1" (
    echo.
    echo [ERRO] Falha no download dos arquivos.
    echo [INFO] Tente baixar manualmente: https://github.com/%REPO%
    pause
    exit /b 1
)

:: Criar Launcher .bat
echo.
echo [PASSO 3] Criando inicializador...
(
    echo @echo off
    echo cd /d "%%~dp0"
    echo powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%%~dp0Updater.ps1"
    echo powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%%~dp0script.ps1"
    echo pause
) > "%INSTALL_DIR%\Iniciar Organizador POSTECH.bat"

:: Criar Atalho na Desktop via PowerShell
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut('%USERPROFILE%\Desktop\Organizador POSTECH.lnk'); $sc.TargetPath = '%INSTALL_DIR%\Iniciar Organizador POSTECH.bat'; $sc.WorkingDirectory = '%INSTALL_DIR%'; $sc.Save()"

:: ==============================================================================
:: FINALIZACAO
:: ==============================================================================
echo.
echo ========================================
echo    INSTALACAO CONCLUIDA COM SUCESSO!
echo ========================================
echo.
echo    Local: %INSTALL_DIR%
echo    Atalho criado na Area de Trabalho
echo.
set /p "EXEC=    Deseja executar a aplicacao agora? [S/N]:, "
if /i "!EXEC!"=="S" (
    start "" "%INSTALL_DIR%\Iniciar Organizador POSTECH.bat"
)

echo.
echo Pressione qualquer tecla para sair...
pause >nul
exit /b 0
