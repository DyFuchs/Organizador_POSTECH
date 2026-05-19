@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1

:: ========================================
::    ORGANIZADOR POSTECH - INSTALADOR
:: ========================================

:: --- CONFIGURACAO ---
set "REPO=DyFuchs/Organizador_POSTECH"
set "BRANCH=main"
set "SELF_DIR=%~dp0"
if "!SELF_DIR:~-1!"=="\" set "SELF_DIR=!SELF_DIR:~0,-1!"

:: --- TELA INICIAL ---
echo ========================================
echo    ORGANIZADOR POSTECH - INSTALADOR
echo ========================================
echo.

:: --- ESCOLHA DO DIRETORIO ---
set "DEFAULT_DIR=!SELF_DIR!"
echo Diretorio de instalacao padrao:
echo   !DEFAULT_DIR!
echo.
set /p "CUSTOM_DIR=Pressione ENTER para aceitar ou digite outro caminho: "
if "!CUSTOM_DIR!"=="" set "CUSTOM_DIR=!DEFAULT_DIR!"

:: Remove aspas se o usuario colocou
set "CUSTOM_DIR=!CUSTOM_DIR:"=!"
:: Remove barra final se existir
if "!CUSTOM_DIR:~-1!"=="\" set "CUSTOM_DIR=!CUSTOM_DIR:~0,-1!"

:: Valida caracteres proibidos
echo !CUSTOM_DIR! | findstr /r "[<>|?*]" >nul 2>&1
if !errorlevel! equ 0 (
    echo [ERRO] Caminho contem caracteres invalidos: ^< ^> ^| ? *
    pause
    exit /b 1
)

:: Valida se o caminho nao esta vazio
if "!CUSTOM_DIR!"=="" (
    echo [ERRO] Caminho vazio.
    pause
    exit /b 1
)

set "INSTALL_DIR=!CUSTOM_DIR!\Organizador_POSTECH"
echo.
echo Instalando em: !INSTALL_DIR!
echo.

:: --- VERIFICAR POWERSHELL ---
echo [1/5] Verificando PowerShell...
where powershell.exe >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERRO] PowerShell nao encontrado neste sistema.
    pause
    exit /b 1
)
echo [OK] PowerShell encontrado.

:: --- VERIFICAR CURL ---
echo [2/5] Verificando metodo de download...
where curl.exe >nul 2>&1
if !errorlevel! equ 0 (
    set "USE_CURL=1"
    echo [OK] curl.exe encontrado.
) else (
    set "USE_CURL=0"
    echo [OK] Usando PowerShell para download.
)

:: --- VERIFICAR SE PASTA JA EXISTE ---
if exist "!INSTALL_DIR!" (
    echo.
    echo [AVISO] A pasta ja existe:
    echo   !INSTALL_DIR!
    set /p "OVERWRITE=Deseja substituir? [S/N]: "
    if /i not "!OVERWRITE!"=="S" (
        echo Instalacao cancelada.
        pause
        exit /b 0
    )
    echo Removendo pasta anterior...
    rmdir /s /q "!INSTALL_DIR!" 2>nul
    if exist "!INSTALL_DIR!" (
        echo [ERRO] Nao foi possivel remover a pasta.
        echo Verifique se algum arquivo esta em uso.
        pause
        exit /b 1
    )
)

:: --- CRIAR DIRETORIO ---
echo [3/5] Criando diretorio de instalacao...
mkdir "!INSTALL_DIR!" 2>nul
if not exist "!INSTALL_DIR!" (
    echo [ERRO] Nao foi possivel criar a pasta.
    echo Verifique suas permissoes neste local.
    pause
    exit /b 1
)
echo [OK] Diretorio criado.

:: --- BAIXAR ARQUIVOS ---
echo [4/5] Baixando arquivos do GitHub...
echo.

set "BASE_URL=https://raw.githubusercontent.com/!REPO!/!BRANCH!"

if "!USE_CURL!"=="1" (
    echo   - script.ps1...
    curl -L -o "!INSTALL_DIR!\script.ps1" "!BASE_URL!/script.ps1" 2>nul
    if !errorlevel! neq 0 (
        echo [ERRO] Falha ao baixar script.ps1
        goto :download_fail
    )

    echo   - Updater.ps1...
    curl -L -o "!INSTALL_DIR!\Updater.ps1" "!BASE_URL!/Updater.ps1" 2>nul
    if !errorlevel! neq 0 (
        echo [ERRO] Falha ao baixar Updater.ps1
        goto :download_fail
    )

    echo   - config.json...
    curl -L -o "!INSTALL_DIR!\config.json" "!BASE_URL!/config.json" 2>nul
    if !errorlevel! neq 0 (
        echo [ERRO] Falha ao baixar config.json
        goto :download_fail
    )

    echo   - version.txt...
    curl -L -o "!INSTALL_DIR!\version.txt" "!BASE_URL!/version.txt" 2>nul
    if !errorlevel! neq 0 (
        echo [AVISO] Falha ao baixar version.txt (opcional)
    )
) else (
    echo   - script.ps1...
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '!BASE_URL!/script.ps1' -OutFile '!INSTALL_DIR!\script.ps1' -UseBasicParsing; exit 0 } catch { exit 1 }"
    if !errorlevel! neq 0 (
        echo [ERRO] Falha ao baixar script.ps1
        goto :download_fail
    )

    echo   - Updater.ps1...
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '!BASE_URL!/Updater.ps1' -OutFile '!INSTALL_DIR!\Updater.ps1' -UseBasicParsing; exit 0 } catch { exit 1 }"
    if !errorlevel! neq 0 (
        echo [ERRO] Falha ao baixar Updater.ps1
        goto :download_fail
    )

    echo   - config.json...
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '!BASE_URL!/config.json' -OutFile '!INSTALL_DIR!\config.json' -UseBasicParsing; exit 0 } catch { exit 1 }"
    if !errorlevel! neq 0 (
        echo [ERRO] Falha ao baixar config.json
        goto :download_fail
    )

    echo   - version.txt...
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '!BASE_URL!/version.txt' -OutFile '!INSTALL_DIR!\version.txt' -UseBasicParsing; exit 0 } catch { exit 1 }"
    if !errorlevel! neq 0 (
        echo [AVISO] Falha ao baixar version.txt (opcional)
    )
)

:: --- VERIFICAR DOWNLOAD ---
if not exist "!INSTALL_DIR!\script.ps1" (
    :download_fail
    echo.
    echo [ERRO] Falha no download dos arquivos.
    echo Verifique sua conexao com a internet.
    echo.
    echo Download manual: https://github.com/!REPO!
    rmdir /s /q "!INSTALL_DIR!" 2>nul
    pause
    exit /b 1
)
echo.
echo [OK] Arquivos baixados com sucesso.

:: --- CRIAR LAUNCHER ---
echo [5/5] Criando launcher...

(
echo @echo off
echo cd /d "%%~dp0"
echo powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%%~dp0Updater.ps1"
echo powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%%~dp0script.ps1"
echo pause
) > "!INSTALL_DIR!\Iniciar_Organizador.bat"

echo [OK] Launcher criado.

:: --- CRIAR ATALHO NA DESKTOP ---
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut('%USERPROFILE%\Desktop\Organizador_POSTECH.lnk'); $sc.TargetPath = '!INSTALL_DIR!\Iniciar_Organizador.bat'; $sc.WorkingDirectory = '!INSTALL_DIR%'; $sc.Description = 'Organizador POSTECH - FIAP'; $sc.Save()" 2>nul

:: --- CONCLUIR ---
echo.
echo ========================================
echo    INSTALACAO CONCLUIDA COM SUCESSO!
echo ========================================
echo.
echo    Pasta: !INSTALL_DIR!
echo    Atalho criado na Area de Trabalho
echo.
set /p "EXECUTAR=Agora executar? [S/N]: "
if /i "!EXECUTAR!"=="S" (
    call "!INSTALL_DIR!\Iniciar_Organizador.bat"
)

echo.
echo Pressione qualquer tecla para sair...
pause >nul
exit /b 0
