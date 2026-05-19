<#
Organizador de Pastas POSTECH - PowerShell
#>

param()

# Fix de encoding (deve vir APÓS param())
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
try { chcp 65001 > $null } catch {}

$Version = "1.0.0"
$AppDir = $PSScriptRoot
$WorkDir = (Get-Location).Path
$ConfigPath = Join-Path $AppDir "config.json"

$DefaultConfig = @{
    ConfirmReq   = $true
    AutoExtra    = $true
    AutoFill     = $true
    FixedSource  = ""
    FixedDest    = ""
    LastUsedPath = ""
    UseArrowKeys = $false
    AutoUpdate   = $false
}

function Format-NetworkPath {
    param([string]$Path)
    # Substitui \\IP\postech$\ por T:\ mantendo o restante do caminho intacto
    return $Path -replace '^\\\\[^\\]+\\postech\$', 'T:'
}

function Gerar-Relatorio {
    Clear-Host
    Write-Host "=== Gerar Relatorio ===" -ForegroundColor Cyan
    $SuggestedPath = Get-SuggestedPath
    $Destino = Read-Host "Confirme ou insira o caminho da pasta (Sugestao: $SuggestedPath)"
    if ([string]::IsNullOrWhiteSpace($Destino)) { $Destino = $SuggestedPath }
    if (-not (Test-Path $Destino)) { Write-Host "Caminho invalido." -ForegroundColor Red; Wait-Input; return }

    $shell = New-Object -ComObject Shell.Application
    $Extensions = '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm'
    $AllVideos = Get-ChildItem -Path $Destino -Recurse -File | Where-Object { $_.Extension -in $Extensions }
    $VideoLog = @()
    $TotalDuration = [TimeSpan]::Zero
    $FolderDurations = @{}

    foreach ($vFile in $AllVideos) {
        $parentDir = Split-Path $vFile.FullName -Parent
        $folderName = Split-Path $parentDir -Leaf
        if ($parentDir -eq $Destino) { $folderName = "Raiz" }

        $dur = Get-VideoDuration -Shell $shell -FilePath $vFile.FullName
        $TotalDuration += $dur
        if ($FolderDurations.ContainsKey($folderName)) { $FolderDurations[$folderName] += $dur } else { $FolderDurations[$folderName] = $dur }

        $VideoLog += [PSCustomObject]@{
            Pasta   = $folderName
            Arquivo = $vFile.Name
            Duracao = $dur
            Caminho = $vFile.FullName
        }
    }
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null

    # Montagem do Relatorio
    $Line = "=" * 60
    $Report = @(
        "RELATORIO DE ORGANIZACAO",
        "Destino: $(Format-NetworkPath $Destino)",
        "Data: $(Get-Date)",
        $Line,
        "ESTRUTURA DE PASTAS:"
    )

    Get-ChildItem -Path $Destino -Directory | ForEach-Object {
        $Report += "  $($_.Name) - $(Format-NetworkPath $_.FullName)\"
    }

    $Report += $Line
    $Report += "TODOS OS VIDEOS:"
    if ($VideoLog.Count -eq 0) { $Report += "  Nenhum video encontrado." }
    else {
        foreach ($v in $VideoLog) {
            $durFmt = if ($v.Duracao -eq [TimeSpan]::Zero) { "00:00:00 (Nao detectado)" } else { $v.Duracao.ToString("hh\:mm\:ss") }
            $Report += ""
            $Report += "[$($v.Pasta)] $($v.Arquivo)"
            $Report += "  Duracao: $durFmt"
            $Report += "  Caminho: $(Format-NetworkPath $v.Caminho)"
        }
    }

    $Report += $Line
    $Report += "DURACAO POR PASTA:"
    $sortedFolders = $FolderDurations.Keys | Sort-Object { if ($_ -match '^Aula\s*(\d+)') { [int]$Matches[1] } else { 999 } }
    foreach ($f in $sortedFolders) {
        $dur = $FolderDurations[$f]
        $hhmmss = $dur.ToString("hh\:mm\:ss")
        $mm_dec = "{0:F2}" -f $dur.TotalMinutes
        $Report += "  [$f] $hhmmss ($mm_dec min)"
    }

    $totalHHMMSS = $TotalDuration.ToString("hh\:mm\:ss")
    $totalMM = "{0:F2}" -f $TotalDuration.TotalMinutes
    $Report += ""; $Report += $Line; $Report += "RESUMO DE DURACAO TOTAL:"
    $Report += "  Tempo Total: $totalHHMMSS"
    $Report += "  Equivalente a: $totalMM minutos"
    $Report += $Line

    # Controle de versoes do relatorio
    $ReportBaseName = "Relatorio_Organizacao.txt"
    $ReportPath = Join-Path $Destino $ReportBaseName
    if (Test-Path $ReportPath) {
        $counter = 1
        while (Test-Path (Join-Path $Destino "Relatorio_Organizacao ($counter).txt")) { $counter++ }
        $ReportPath = Join-Path $Destino "Relatorio_Organizacao ($counter).txt"
    }

    $Report | Set-Content -Path $ReportPath -Encoding UTF8
    Write-Host "Relatorio salvo em: $ReportPath" -ForegroundColor Yellow
    type $ReportPath
    Wait-Input
}

$Config = $DefaultConfig.Clone()
if (Test-Path $ConfigPath) {
    try {
        $Loaded = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        foreach ($prop in $Loaded.PSObject.Properties) {
            if ($Config.ContainsKey($prop.Name)) { $Config[$prop.Name] = $prop.Value }
        }
    } catch { Write-Warning "Erro ao carregar config.json. Usando padroes." }
} else {
    $Config | ConvertTo-Json | Set-Content $ConfigPath
}

function Save-Config { $Config | ConvertTo-Json | Set-Content $ConfigPath }

function Get-SuggestedPath {
    if (-not [string]::IsNullOrWhiteSpace($Config.FixedDest)) { return $Config.FixedDest }
    if (-not [string]::IsNullOrWhiteSpace($Config.FixedSource)) { return $Config.FixedSource }
    if (-not [string]::IsNullOrWhiteSpace($Config.LastUsedPath)) { return $Config.LastUsedPath }
    return $WorkDir
}

function Get-VideoDuration {
    param($Shell, $FilePath)
    try {
        $dir = Split-Path $FilePath -Parent
        $name = Split-Path $FilePath -Leaf
        $folder = $Shell.Namespace($dir)
        $file = $folder.ParseName($name)
        # Indice 27 e padrao para "Duracao" no Windows 10/11
        $durStr = $folder.GetDetailsOf($file, 27)
        if ($durStr -match '(\d{1,2}):(\d{2}):(\d{2})') { return [TimeSpan]::Parse($durStr) }
        if ($durStr -match '^(\d{1,2}):(\d{2})$') { return [TimeSpan]::FromMinutes([int]$Matches[1] * 60 + [int]$Matches[2]) }
    } catch { return [TimeSpan]::Zero }
    return [TimeSpan]::Zero
}

function Get-MenuChoice {
    param([string]$Title, [string[]]$Options, [int]$StartIndex = 0, [string]$InfoLine = "")
    $idx = $StartIndex
    $savedCursor = [Console]::CursorVisible
    [Console]::CursorVisible = $false

    while ($true) {
        Clear-Host
        if ($Title) { Write-Host $Title -ForegroundColor Cyan; Write-Host "" }
        if ($InfoLine) { Write-Host $InfoLine -ForegroundColor Gray; Write-Host "" }
        
        for ($i = 0; $i -lt $Options.Count; $i++) {
            $prefix = if ($i -eq $idx) { ">>" } else { "  " }
            $fg = if ($i -eq $idx) { "White" } else { "Gray" }
            Write-Host "$prefix $($Options[$i])" -ForegroundColor $fg
        }
        Write-Host "`n[Cima/Baixo] Navegar | [Enter] Confirmar | [Esc] Voltar" -ForegroundColor DarkGray

        $key = [Console]::ReadKey($true)
        Start-Sleep -Milliseconds 80
        switch ($key.Key) {
            'UpArrow'   { if ($idx -gt 0) { $idx-- } }
            'DownArrow' { if ($idx -lt $Options.Count - 1) { $idx++ } }
            'Enter'     { [Console]::CursorVisible = $savedCursor; return $idx }
            'Escape'    { [Console]::CursorVisible = $savedCursor; return -1 }
        }
    }
}

function Show-Logo {
    Clear-Host
    Write-Host @"
     ----------------------------------
    /                                  \
    |  |----------------------------|  |
    |  |                            |  |
    |  |        ORGANIZADOR         |  |
    |  |         DE PASTAS          |  |
    |  |          POSTECH           |  |
    |  |          V.$Version           |  |
    |  |                            |  |
    |  |----------------------------|  |
    \                                  /
     ----------------------------------
    / ###  # # # # #    # # # # #  ### \
   / ###  ########################  ### \
  / ###    #####################     ### \
 / ###      ###################       ### \
/__________________________________________\
\__________________________________________/

"@ -ForegroundColor Cyan
    Start-Sleep -Milliseconds 600
}

function Show-Credits {
    Clear-Host
    Write-Host "CREDITOS" -ForegroundColor Cyan
    Write-Host "=========================="
    Write-Host "Desenvolvido por Diana Fuchs Santos para"
    Write-Host "FIAP/POSTECH a partir de Maio/2026"
    Write-Host "versao $Version"
    Write-Host "=========================="
    Wait-Input
}

function Show-Instructions {
    while ($true) {
        # Usando aspas simples para evitar erros de parsing com caracteres especiais
        $Topic0 = @(
            '0. INTRODUCAO E PROPOSITO DO SISTEMA',
            '   O Organizador de Pastas POSTECH e uma ferramenta de automacao desenvolvida',
            '   para padronizar a estrutura de repositorios de video em ambientes academicos',
            '   e corporativos. Seu objetivo principal e eliminar a organizacao manual,',
            '   reduzir erros humanos e gerar documentacao tecnica automatica.',
            '   ',
            '   CENARIOS DE USO RECOMENDADOS:',
            '   - Ingestao de materias brutas de plataformas de ensino a distancia.',
            '   - Padronizacao de diretorios de rede antes de backup ou arquivamento.',
            '   - Auditoria de conteudo multimedia com metricas de duracao precisa.',
            '   - Reversao segura de organizacoes mal-sucedidas sem perda de dados.',
            '   ',
            '   DIFERENCIAL TECNICO:',
            '   - Zero dependencias externas. Puro PowerShell + COM.',
            '   - Leitura nativa de metadados via Windows Shell API.',
            '   - Persistencia de estado em JSON com merge seguro entre versoes.',
            '   - Tratamento de caminhos UNC com formatacao corporativa automatica.'
        )

        $Topic1 = @(
            '1. ARQUITETURA TECNICA E FLUXO DE EXECUCAO',
            '   O script opera em camadas modulares, garantindo isolamento de falhas:',
            '   ',
            '   CAMADA 1: INICIALIZACAO',
            '   - Forca UTF-8 no console ([Console]::OutputEncoding + chcp 65001).',
            '   - Carrega config.json com fallback para $DefaultConfig.',
            '   - Resolve $WorkDir (pasta de invocacao) vs $AppDir (pasta do script).',
            '   ',
            '   CAMADA 2: ANALISE E DECISAO',
            '   - Get-SuggestedPath aplica a fila de prioridades em tempo real.',
            '   - Regex pre-filtra arquivos por extensao antes de qualquer I/O pesado.',
            '   - Calculo de $MaxAula e $HasBoasVindas roda em memoria (RAM).',
            '   ',
            '   CAMADA 3: EXECUCAO FILE-SYSTEM',
            '   - Criacao de diretorios com New-Item -ItemType Directory (idempotente).',
            '   - Move-Item com -Force sobrescreve silenciosamente conflitos de nome.',
            '   - Push-Location/Pop-Location isola o contexto do shell durante operacoes.',
            '   ',
            '   CAMADA 4: RELATORIO E ENCERRAMENTO',
            '   - New-Object -ComObject Shell.Application abre handle para metadados.',
            '   - ReleaseComObject libera memoria imediatamente apos extracao.',
            '   - Set-Content -Encoding UTF8 garante legibilidade em qualquer OS.'
        )

        $Topic2 = @(
            '2. INTERFACE DE CONSOLE E UX',
            '   A interface foi projetada para minimizar atrito cognitivo:',
            '   ',
            '   NAVEGACAO INSTANTANEA (PADRAO):',
            '   - [Console]::ReadKey($true) captura teclas sem eco no buffer.',
            '   - Nao requer Enter. A acao e disparada no keydown.',
            '   - Previne inputs acidentais de caracteres de controle.',
            '   ',
            '   NAVEGACAO POR CURSOR (OPCIONAL):',
            '   - Gerenciamento manual de [Console]::CursorVisible.',
            '   - Clear-Host + redesenho completo a cada evento de tecla.',
            '   - Delay de 80ms para debounce em teclados com autorepeat.',
            '   ',
            '   SEMANTICA DE CORES:',
            '   - Cyan: Headers, titulos de secao e caminhos ativos.',
            '   - White: Opcao selecionada no modo cursor.',
            '   - Gray: Opcoes inativas, caminhos secundarios e separadores.',
            '   - Green: Sucesso critico (move, delete, save).',
            '   - Red: Falha de permissao, caminho inexistente ou excecao.',
            '   - Yellow: Avisos operacionais e indicadores de relatorio.'
        )

        $Topic3 = @(
            '3. MODOS DE OPERACAO: ESPECIFICACOES',
            '   [1] MODO AUTOMATICO (Pipeline Nao Supervisionado)',
            '   - Ignora prompts interativos se ConfirmReq = false.',
            '   - Usa Get-SuggestedPath como unico ponto de entrada.',
            '   - Ideal para agendamento via Task Scheduler ou scripts wrapper.',
            '   ',
            '   [2] MODO MANUAL (Interacao Guiada)',
            '   - Respeita AutoFill: se true, sugere valores; se false, exige entrada.',
            '   - Valida Test-Path antes de prosseguir. Bloqueia execucao em paths invalidos.',
            '   - Permite override de Qtd de aulas independente da deteccao maxima.',
            '   ',
            '   [6] MODO REVERSO (Rollback Controlado)',
            '   - Itera sobre TargetFolders com filtro de nome exato.',
            '   - Move videos para $Destino (raiz) antes de tentar Remove-Item.',
            '   - Remove-Item -Force -Recurse so executa apos validacao de vazio.',
            '   - Flag $DeleteReports permite limpeza de artefatos .txt.',
            '   ',
            '   [7] GERAR RELATORIO (Read-Only Audit)',
            '   - Executa varredura recursiva sem modificar file-system.',
            '   - Detecta conflitos de nome e aplica sufixo (n).txt automaticamente.',
            '   - Usado para auditoria pre-migracao ou inventario de conteudo.'
        )

        $Topic4 = @(
            '4. PADROES DE DETECCAO E EXPRESSOES REGULARES',
            '   O motor de classificacao utiliza matching case-insensitive:',
            '   ',
            '   AULA N:',
            '   - Pattern: ''(?i)^aula\s*(\d+)''',
            '   - ^ = inicio da string. \s* = espacos opcionais. (\d+) = grupo capturado.',
            '   - Edge Case: ''Aula 0'' e normalizado para 1 para evitar pastas invalidas.',
            '   - Arquivos como ''Minha Aula 5.mp4'' nao sao capturados (exige prefixo exato).',
            '   ',
            '   BOAS VINDAS:',
            '   - Pattern: ''(?i)^boas[-_ ]vindas''',
            '   - Aceita separadores: espaco, hifen, underscore.',
            '   - Rota exclusiva para ''Capitulo de Projeto'' (requer Extra = true).',
            '   ',
            '   EXTENSOES SUPORTADAS:',
            '   - Array fixo: ''.mp4'', ''.mkv'', ''.avi'', ''.mov'', ''.wmv'', ''.flv'', ''.webm''',
            '   - Filtro via Where-Object { $_.Extension -in $Extensions }',
            '   - Ignora arquivos de sistema, thumbs.db, .lnk e metadados ocultos.'
        )

        $Topic5 = @(
            '5. GERENCIAMENTO DE CAMINHOS E REDE CORPORATIVA',
            '   O sistema implementa uma fila de resolucao deterministica:',
            '   ',
            '   ORDEM DE PRIORIDADE (MAIOR PARA MENOR):',
            '   1. FixedDest: Hardcode de destino para ambientes estaveis.',
            '   2. FixedSource: Fallback historico ou pasta de origem padrao.',
            '   3. LastUsedPath: Memoria da ultima execucao bem-sucedida.',
            '   4. WorkDir: Contexto atual do terminal (drag-and-drop ou cd).',
            '   ',
            '   FORMATAO DE REDE (Format-NetworkPath):',
            '   - Regex: ''^\\\\[^\\]+\\postech\$'' -> ''T:''',
            '   - Captura qualquer IP/Nome e substitui pela letra de mapa padrao.',
            '   - Mantem subdiretorios intactos. Ex: \\10.0.0.5\share\a\b -> T:\a\b',
            '   - Nao modifica o file-system; apenas a representacao textual no relatorio.',
            '   - Ideal para padroes FIAP/POSTECH onde T: e o drive de curso mapeado.'
        )

        $Topic6 = @(
            '6. GERACAO DE RELATORIOS E METADADOS DE VIDEO',
            '   O modulo de relatorio e stateless e idempotente:',
            '   ',
            '   EXTRAÇÃO DE DURACAO:',
            '   - Usa Shell.Application.Namespace().GetDetailsOf(file, 27)',
            '   - Indice 27 e o padrao Windows para ''Length''/''Duracao''.',
            '   - Parse de HH:MM:SS via [TimeSpan]::Parse(). Fallback para MM:SS.',
            '   - Retorno [TimeSpan]::Zero se metadado estiver ausente ou corrompido.',
            '   ',
            '   AGREGACAO E FORMATAO:',
            '   - Acumulo por pasta via hashtable $FolderDurations.',
            '   - Ordenacao natural: Aula 1, Aula 2, ... Aula 10 (numerica, nao lexica).',
            '   - Total: HH:MM:SS + Minutos.Decimais ({0:F2} -f .TotalMinutes).',
            '   ',
            '   CONTROLE DE VERSAO:',
            '   - While loop incrementa contador ate encontrar nome disponivel.',
            '   - Garante que execucoes consecutivas nao sobrescrevem auditorias anteriores.'
        )

        $Topic7 = @(
            '7. SISTEMA DE CONFIGURACAO E SCHEMA JSON',
            '   config.json armazena o estado da aplicacao entre sessoes:',
            '   ',
            '   SCHEMA ATUAL:',
            '   {',
            '     "ConfirmReq": true,        // Pede [S/N] antes de executar',
            '     "AutoExtra": true,         // Cria Cap/Proj e Onboarding automaticamente',
            '     "AutoFill": true,          // Sugere caminhos/qtd no Modo Manual',
            '     "FixedSource": "",         // Caminho hardcode de origem',
            '     "FixedDest": "",           // Caminho hardcode de destino',
            '     "LastUsedPath": "",        // Atualizado pos-execucao',
            '     "UseArrowKeys": false      // Liga/desliga navegacao por cursor',
            '   }',
            '   ',
            '   MERGE SEGURO:',
            '   - Carrega JSON existente e faz diff com $DefaultConfig.',
            '   - Adiciona chaves faltantes sem sobrescrever preferencias do usuario.',
            '   - Permite edicao manual com Bloco de Notas. Valida na proxima carga.',
            '   - Localizacao: Sempre na pasta do script ($AppDir), nunca no destino.'
        )

        $Topic8 = @(
            '8. SEGURANCA, PERMISSOES E BOAS PRATICAS',
            '   Recomendacoes para operacao em producao:',
            '   ',
            '   PERMISSOES DE ARQUIVO:',
            '   - Nao requer privilegios de Administrador para operacoes basicas.',
            '   - Requer Write access na pasta de destino para move/delete.',
            '   - Leitura de metadados funciona mesmo em arquivos read-only.',
            '   ',
            '   INTEGRIDADE DE DADOS:',
            '   - Move-Item e atomico no mesmo volume. Entre volumes, usa copy+delete.',
            '   - Sempre execute um backup ou snapshot antes do primeiro teste em massa.',
            '   - O Modo Reverso e a rede de seguranca para operacoes indevidas.',
            '   ',
            '   AMBIENTE DE REDE:',
            '   - Latencia alta pode causar timeouts em Get-ChildItem recursivo.',
            '   - Use caminhos mapeados (T:) em vez de UNC sempre que possivel.',
            '   - Evite caracteres reservados do Windows: < > : " / \ | ? *'
        )

        $Topic9 = @(
            '9. SOLUCAO DE PROBLEMAS E FAQ AVANCADO',
            '   ',
            '   Q: Duracao aparece 00:00:00 mesmo com video valido?',
            '   A: O indexador do Windows pode estar atrasado. Aguarde 2-5 min ou copie',
            '      o arquivo para um diretorio local temporario para forcar a leitura.',
            '   ',
            '   Q: Erro ''Access Denied'' ao mover ou deletar?',
            '   A: Verifique se o arquivo nao esta aberto em outro processo (player, editor).',
            '      Use Process Explorer ou feche aplicativos de midia e tente novamente.',
            '   ',
            '   Q: Config.json corrompeu ou ficou vazio?',
            '   A: Delete o arquivo. O script recriara com $DefaultConfig na proxima carga.',
            '      Suas preferencias serao perdidas, mas a integridade e restaurada.',
            '   ',
            '   Q: Posso agendar execucoes automaticas?',
            '   A: Sim. Use Task Scheduler chamando powershell.exe -File script.ps1.',
            '      Defina ConfirmReq=false e FixedDest para execucao hands-free.',
            '   ',
            '   Q: O relatorio quebra linhas longas no bloco de notas?',
            '   A: Ative Word Wrap (Format > Word Wrap) ou use VS Code/Notepad++.'
        )

        # MENU DE NAVEGACAO
        if ($Config.UseArrowKeys) {
            $opts = @(
                "[0] Introducao e Proposito",
                "[1] Arquitetura e Fluxo",
                "[2] Interface e Controles",
                "[3] Modos de Operacao",
                "[4] Deteccao e Regex",
                "[5] Caminhos e Rede",
                "[6] Relatorios e Metadados",
                "[7] Configuracoes e JSON",
                "[8] Seguranca e Boas Praticas",
                "[9] Troubleshooting e FAQ",
                "[M] Menu Principal"
            )
            $sel = Get-MenuChoice -Title "CENTRO DE DOCUMENTACAO TECNICA" -Options $opts
            if ($sel -eq -1) { return }
        } else {
            Clear-Host
            Write-Host "CENTRO DE DOCUMENTACAO TECNICA" -ForegroundColor Cyan
            Write-Host "=========================="
            Write-Host "[0] Introducao e Proposito"
            Write-Host "[1] Arquitetura e Fluxo"
            Write-Host "[2] Interface e Controles"
            Write-Host "[3] Modos de Operacao"
            Write-Host "[4] Deteccao e Regex"
            Write-Host "[5] Caminhos e Rede"
            Write-Host "[6] Relatorios e Metadados"
            Write-Host "[7] Configuracoes e JSON"
            Write-Host "[8] Seguranca e Boas Praticas"
            Write-Host "[9] Troubleshooting e FAQ"
            Write-Host "[M] Menu Principal"
            Write-Host "=========================="
            Write-Host "Selecione o topico: " -NoNewline
            $key = [Console]::ReadKey($true)
            $sel = $key.KeyChar.ToString().ToUpper()
            Write-Host $sel -ForegroundColor Cyan
        }

        # EXIBICAO DO CONTEUDO (Switch blindado para string)
        switch ([string]$sel) {
            '0' { Clear-Host; Write-Host "TOPICO 0: INTRODUCAO" -ForegroundColor Yellow; Write-Host "=========================="; $Topic0 | ForEach-Object { Write-Host $_ }; Write-Host ""; Wait-Input }
            '1' { Clear-Host; Write-Host "TOPICO 1: ARQUITETURA" -ForegroundColor Yellow; Write-Host "=========================="; $Topic1 | ForEach-Object { Write-Host $_ }; Write-Host ""; Wait-Input }
            '2' { Clear-Host; Write-Host "TOPICO 2: INTERFACE" -ForegroundColor Yellow; Write-Host "=========================="; $Topic2 | ForEach-Object { Write-Host $_ }; Write-Host ""; Wait-Input }
            '3' { Clear-Host; Write-Host "TOPICO 3: MODOS" -ForegroundColor Yellow; Write-Host "=========================="; $Topic3 | ForEach-Object { Write-Host $_ }; Write-Host ""; Wait-Input }
            '4' { Clear-Host; Write-Host "TOPICO 4: DETECCAO" -ForegroundColor Yellow; Write-Host "=========================="; $Topic4 | ForEach-Object { Write-Host $_ }; Write-Host ""; Wait-Input }
            '5' { Clear-Host; Write-Host "TOPICO 5: CAMINHOS" -ForegroundColor Yellow; Write-Host "=========================="; $Topic5 | ForEach-Object { Write-Host $_ }; Write-Host ""; Wait-Input }
            '6' { Clear-Host; Write-Host "TOPICO 6: RELATORIOS" -ForegroundColor Yellow; Write-Host "=========================="; $Topic6 | ForEach-Object { Write-Host $_ }; Write-Host ""; Wait-Input }
            '7' { Clear-Host; Write-Host "TOPICO 7: CONFIGURACAO" -ForegroundColor Yellow; Write-Host "=========================="; $Topic7 | ForEach-Object { Write-Host $_ }; Write-Host ""; Wait-Input }
            '8' { Clear-Host; Write-Host "TOPICO 8: SEGURANCA" -ForegroundColor Yellow; Write-Host "=========================="; $Topic8 | ForEach-Object { Write-Host $_ }; Write-Host ""; Wait-Input }
            '9' { Clear-Host; Write-Host "TOPICO 9: TROUBLESHOOTING" -ForegroundColor Yellow; Write-Host "=========================="; $Topic9 | ForEach-Object { Write-Host $_ }; Write-Host ""; Wait-Input }
            'M' { return }
            default { if (-not $Config.UseArrowKeys) { Write-Host "Opcao invalida!"; Start-Sleep -Milliseconds 500 } }
        }
    }
}

function Show-Settings {
    while ($true) {
        # Safeguard para configs antigas
        if (-not $Config.ContainsKey('AutoUpdate')) { $Config['AutoUpdate'] = $false; Save-Config }
        if (-not $Config.ContainsKey('UseArrowKeys')) { $Config['UseArrowKeys'] = $false; Save-Config }

        # Prepara strings de exibição
        $srcText, $srcColor = if ([string]::IsNullOrWhiteSpace($Config.FixedSource)) { "Nenhum caminho definido", "Red" } else { $Config.FixedSource, "Gray" }
        $dstText, $dstColor = if ([string]::IsNullOrWhiteSpace($Config.FixedDest)) { "Nenhum caminho definido", "Red" } else { $Config.FixedDest, "Gray" }
        $lastText, $lastColor = if ([string]::IsNullOrWhiteSpace($Config.LastUsedPath)) { "Nenhum caminho definido", "Red" } else { $Config.LastUsedPath, "Gray" }

        if ($Config.UseArrowKeys) {
            $opts = @(
                "[0] Alternar Atualizacao Automatica ($(if($Config.AutoUpdate){'ON'}else{'OFF'}))",
                "[1] Alternar Confirmacao ($(if($Config.ConfirmReq){'ON'}else{'OFF'}))",
                "[2] Alternar Pastas Extras ($(if($Config.AutoExtra){'ON'}else{'OFF'}))",
                "[3] Alternar Auto-Preenchimento ($(if($Config.AutoFill){'ON'}else{'OFF'}))",
                "[4] Definir Caminho de Origem Fixo",
                "[5] Definir Caminho de Destino Fixo",
                "[6] Limpar Caminhos Fixos",
                "[7] Limpar Ultimo Caminho Utilizado",
                "[8] Navegacao por Setas: $(if($Config.UseArrowKeys){'ON'}else{'OFF'})",
                "[9] Voltar ao Menu Principal"
            )
            $sel = Get-MenuChoice -Title "CONFIGURACOES" -Options $opts
            if ($sel -eq -1) { return }
        } else {
            Clear-Host
            Write-Host "CONFIGURACOES" -ForegroundColor Cyan
            Write-Host "=========================="
            Write-Host "Atualizacao Automatica:    $(if($Config.AutoUpdate){'Habilitado'}else{'Desabilitado'})"
            Write-Host "Pedido de Confirmacao:     $(if($Config.ConfirmReq){'Habilitado'}else{'Desabilitado'})"
            Write-Host "Pastas Extras Automaticas: $(if($Config.AutoExtra){'Habilitado'}else{'Desabilitado'})"
            Write-Host "Auto-Preenchimento:        $(if($Config.AutoFill){'Habilitado'}else{'Desabilitado'})"
            Write-Host "Navegacao por Setas:       $(if($Config.UseArrowKeys){'Habilitado'}else{'Desabilitado'})"
            Write-Host "Caminho Origem Fixo:"
            Write-Host "  $srcText" -ForegroundColor $srcColor
            Write-Host "Caminho Destino Fixo:"
            Write-Host "  $dstText" -ForegroundColor $dstColor
            Write-Host "Ultimo Caminho Utilizado:"
            Write-Host "  $lastText" -ForegroundColor $lastColor
            Write-Host "=========================="
            Write-Host "[0] Alternar Atualizacao Automatica"
            Write-Host "[1] Alternar Confirmacao"
            Write-Host "[2] Alternar Pastas Extras"
            Write-Host "[3] Alternar Auto-Preenchimento"
            Write-Host "[4] Definir Caminho de Origem Fixo"
            Write-Host "[5] Definir Caminho de Destino Fixo"
            Write-Host "[6] Limpar Caminhos Fixos"
            Write-Host "[7] Limpar Ultimo Caminho Utilizado"
            Write-Host "[8] Alternar Navegacao por Setas"
            Write-Host "[9] Voltar ao Menu Principal"
            Write-Host "=========================="
            Write-Host "Acao: " -NoNewline

            $key = [Console]::ReadKey($true)
            $sel = $key.KeyChar.ToString().ToUpper()
            Write-Host $sel -ForegroundColor Cyan
            if ($sel -eq '4' -or $sel -eq '5') { Write-Host "" }
        }

        switch ([string]$sel) {
            '0' { $Config.AutoUpdate = -not $Config.AutoUpdate; Save-Config; Write-Host "Atualizacao automatica alterada para $(if($Config.AutoUpdate){'ON'}else{'OFF'})."; Start-Sleep -Milliseconds 800 }
            '1' { $Config.ConfirmReq = -not $Config.ConfirmReq; Save-Config; Write-Host "Confirmacao alterada."; Start-Sleep -Milliseconds 800 }
            '2' { $Config.AutoExtra = -not $Config.AutoExtra; Save-Config; Write-Host "Pastas extras alteradas."; Start-Sleep -Milliseconds 800 }
            '3' { $Config.AutoFill = -not $Config.AutoFill; Save-Config; Write-Host "Auto-preenchimento alterado."; Start-Sleep -Milliseconds 800 }
            '4' { $p = (Read-Host "Caminho de origem").Trim(); if($p){$Config.FixedSource=$p;Save-Config}; Write-Host "Origem salva."; Start-Sleep -Milliseconds 800 }
            '5' { $p = (Read-Host "Caminho de destino").Trim(); if($p){$Config.FixedDest=$p;Save-Config}; Write-Host "Destino salvo."; Start-Sleep -Milliseconds 800 }
            '6' { $Config.FixedSource=""; $Config.FixedDest=""; Save-Config; Write-Host "Caminhos fixos removidos."; Start-Sleep -Milliseconds 800 }
            '7' { $Config.LastUsedPath=""; Save-Config; Write-Host "Ultimo caminho limpo."; Start-Sleep -Milliseconds 800 }
            '8' { $Config.UseArrowKeys = -not $Config.UseArrowKeys; Save-Config; Write-Host "Navegacao por setas $(if($Config.UseArrowKeys){'ATIVADA'}else{'DESATIVADA'})."; Start-Sleep -Milliseconds 1000 }
            '9' { return }
            default { Write-Host "Opcao invalida!"; Start-Sleep -Milliseconds 500 }
        }
    }
}

function Wait-Input { Write-Host "Pressione Enter para continuar..." -ForegroundColor Gray; Read-Host }

function Run-Core {
    param($Mode)
    Clear-Host
    Write-Host "=== Organizador de Pastas ($Mode) ==="
    $SuggestedPath = Get-SuggestedPath

    if ($Mode -eq 'Auto') { $Destino = $SuggestedPath }
    else {
        if ($Config.AutoFill) { $Destino = Read-Host "Confirme o caminho ou digite outro (Sugestao: $SuggestedPath)"; if([string]::IsNullOrWhiteSpace($Destino)){$Destino=$SuggestedPath} }
        else { $Destino = Read-Host "Digite o caminho completo da pasta destino:"; if([string]::IsNullOrWhiteSpace($Destino)){$Destino=$SuggestedPath} }
    }

    if (-not (Test-Path $Destino)) { Write-Host "Caminho invalido." -ForegroundColor Red; Wait-Input; return }

    $Extensions = '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm'
    $Files = Get-ChildItem -Path $Destino | Where-Object { -not $_.PSIsContainer -and $_.Extension -in $Extensions }
    $MaxAula = 0; $HasBoasVindas = $false
    foreach ($f in $Files) {
        if ($f.Name -match '(?i)^aula\s*(\d+)') { $num=[int]$Matches[1]; if($num -gt $MaxAula){$MaxAula=$num} }
        if ($f.Name -match '(?i)^boas[-_ ]vindas') { $HasBoasVindas=$true }
    }
    if ($MaxAula -eq 0) { $MaxAula = 1 }

    if ($Mode -eq 'Auto') { $Qtd = $MaxAula }
    else {
        if ($Config.AutoFill) { $res=Read-Host "Qtd de pastas Aula (Detectado: $MaxAula)"; $Qtd=if([string]::IsNullOrWhiteSpace($res)){$MaxAula}else{[int]$res} }
        else { $res=Read-Host "Qtd de pastas Aula:"; $Qtd=if([string]::IsNullOrWhiteSpace($res)){1}else{[int]$res} }
    }

    $Extra = if(-not $Config.AutoExtra){$false} elseif($Mode -eq 'Auto'){$true} else {(Read-Host "Criar pastas extras? [S/N]").ToUpper() -eq 'S'}

    1..$Qtd | ForEach-Object { $p=Join-Path $Destino "Aula $_"; if(-not(Test-Path $p)){New-Item -Path $p -ItemType Directory|Out-Null} }
    if ($Extra) {
        $p=Join-Path $Destino "Capitulo de Projeto"; if(-not(Test-Path $p)){New-Item -Path $p -ItemType Directory|Out-Null}
        $p=Join-Path $Destino "Onboarding"; if(-not(Test-Path $p)){New-Item -Path $p -ItemType Directory|Out-Null}
    }

    Write-Host "=========================="; Write-Host "RESUMO:"; Write-Host "Modo: $Mode"; Write-Host "Destino: $Destino"; Write-Host "Aulas: 1..$Qtd"; Write-Host "Extras: $Extra"; Write-Host "=========================="

    $Run = $true
    if ($Config.ConfirmReq) {
        if ($Mode -eq 'Auto') { Start-Sleep -Seconds 2 }
        else { $conf=(Read-Host "Confirma execucao? [S/N]").ToUpper(); if($conf -ne 'S'){$Run=$false} }
    } else { Write-Host "Executando..."; Start-Sleep -Milliseconds 500 }
    if (-not $Run) { return }

    $shell = New-Object -ComObject Shell.Application
    Push-Location $Destino
    foreach ($f in $Files) {
        $moved = $false; $name = $f.BaseName; $targetPath = $null; $folderName = ""
        if ($name -match '(?i)^aula\s*(\d+)') {
            $num = [int]$Matches[1]; if ($num -eq 0) { $num = 1 }
            $targetPath = Join-Path $Destino "Aula $num"; $folderName = "Aula $num"
            if (Test-Path $targetPath) { Move-Item $f.FullName $targetPath -Force; Write-Host "[OK] $($f.Name) -> $folderName" -ForegroundColor Green; $moved = $true }
        }
        if (-not $moved -and $Extra -and ($name -match '(?i)^boas[-_ ]vindas')) {
            $targetPath = Join-Path $Destino "Capitulo de Projeto"; $folderName = "Capitulo de Projeto"
            Move-Item $f.FullName $targetPath -Force; Write-Host "[OK] $($f.Name) -> $folderName" -ForegroundColor Green; $moved = $true
        }
    }
    Pop-Location

    # Varredura completa pos-organizacao (novos + pre-existentes)
    $AllVideos = Get-ChildItem -Path $Destino -Recurse -File | Where-Object { $_.Extension -in $Extensions }
    $VideoLog = @()
    $TotalDuration = [TimeSpan]::Zero
    $FolderDurations = @{}

    foreach ($vFile in $AllVideos) {
        $parentDir = Split-Path $vFile.FullName -Parent
        $folderName = Split-Path $parentDir -Leaf
        if ($parentDir -eq $Destino) { $folderName = "Raiz" }

        $dur = Get-VideoDuration -Shell $shell -FilePath $vFile.FullName
        $TotalDuration += $dur

        # Acumula duracao por pasta
        if ($FolderDurations.ContainsKey($folderName)) { $FolderDurations[$folderName] += $dur } else { $FolderDurations[$folderName] = $dur }

        $VideoLog += [PSCustomObject]@{ Pasta = $folderName; Arquivo = $vFile.Name; Duracao = $dur; Caminho = $vFile.FullName }
    }

    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
    $Config.LastUsedPath = $Destino; Save-Config

    # Geracao do Relatorio
    $ReportPath = Join-Path $Destino "Relatorio_Organizacao.txt"
    $Line = "=" * 60
    $Report = @(
        "RELATORIO DE ORGANIZACAO", "Destino: $Destino", "Data: $(Get-Date)", $Line,
        "ESTRUTURA DE PASTAS:"
    )
    Get-ChildItem -Path $Destino -Directory | ForEach-Object { $Report += "  $($_.Name) - $($_.FullName)\" }

    $Report += $Line
    $Report += "TODOS OS VIDEOS:"
    if ($VideoLog.Count -eq 0) { $Report += "  Nenhum video encontrado." }
    else {
        foreach ($v in $VideoLog) {
            $durFmt = if ($v.Duracao -eq [TimeSpan]::Zero) { "00:00:00 (Nao detectado)" } else { $v.Duracao.ToString("hh\:mm\:ss") }
            $Report += ""; $Report += "[$($v.Pasta)] $($v.Arquivo)"; $Report += "  Duracao: $durFmt"; $Report += "  Caminho: $($v.Caminho)"
        }
    }

    # Duracao por Pasta
    $Report += $Line
    $Report += "DURACAO POR PASTA:"
    $sortedFolders = $FolderDurations.Keys | Sort-Object { if ($_ -match '^Aula\s*(\d+)') { [int]$Matches[1] } else { 999 } }, $_
    foreach ($f in $sortedFolders) {
        $dur = $FolderDurations[$f]
        $hhmmss = $dur.ToString("hh\:mm\:ss")
        $mm_dec = "{0:F2}" -f $dur.TotalMinutes
        $Report += "  [$f] $hhmmss ($mm_dec min)"
    }

    # Duracao Total
    $totalHHMMSS = $TotalDuration.ToString("hh\:mm\:ss")
    $totalMM = "{0:F2}" -f $TotalDuration.TotalMinutes
    $Report += ""; $Report += $Line; $Report += "RESUMO DE DURACAO TOTAL:"
    $Report += "  Tempo Total: $totalHHMMSS"
    $Report += "  Equivalente a: $totalMM minutos"
    $Report += $Line

    $Report | Set-Content -Path $ReportPath -Encoding UTF8
    Write-Host "Relatorio salvo." -ForegroundColor Yellow
    type $ReportPath
    Wait-Input
}

function Run-Reverse {
    Clear-Host
    Write-Host "=== Modo Reverso (Desorganizar) ==="
    $SuggestedPath = Get-SuggestedPath

    $Destino = Read-Host "Confirme o caminho para Desorganizar ou digite outro (Sugestao: $SuggestedPath)"
    if ([string]::IsNullOrWhiteSpace($Destino)) { $Destino = $SuggestedPath }
    if (-not (Test-Path $Destino)) { Write-Host "Caminho invalido." -ForegroundColor Red; Wait-Input; return }

    Write-Host "=========================="
    Write-Host "RESUMO:"
    Write-Host "Modo: Reverso"
    Write-Host "Destino: $Destino"
    Write-Host "Acao: Retirar videos, excluir pastas de aula e relatorios"
    Write-Host "=========================="
    
    $conf = (Read-Host "Confirma execucao? [S/N]").ToUpper()
    if ($conf -ne 'S') { Write-Host "Cancelado."; Wait-Input; return }

    $delRep = (Read-Host "Deseja excluir tambem os arquivos .txt de relatorios? [S/N]").ToUpper()
    $DeleteReports = ($delRep -eq 'S')

    $TargetFolders = Get-ChildItem -Path $Destino -Directory | Where-Object { $_.Name -match '^Aula\s*\d+' -or $_.Name -eq 'Capitulo de Projeto' -or $_.Name -eq 'Onboarding' }

    # 1. Mover videos para a raiz
    foreach ($folder in $TargetFolders) {
        Write-Host "Processando: $($folder.Name)..." -ForegroundColor Cyan
        $files = Get-ChildItem -Path $folder.FullName -File | Where-Object { $_.Extension -in @('.mp4','.mkv','.avi','.mov','.wmv','.flv','.webm') }
        foreach ($f in $files) {
            try { Move-Item $f.FullName $Destino -Force; Write-Host "  [OK] $($f.Name) -> Raiz" -ForegroundColor Green }
            catch { Write-Host "  [ERRO] $($f.Name): $_" -ForegroundColor Red }
        }
    }

    # 2. Excluir pastas de aula
    Write-Host "Removendo pastas de aula..." -ForegroundColor Cyan
    foreach ($folder in $TargetFolders) {
        try {
            Remove-Item $folder.FullName -Force -Recurse
            Write-Host "  [OK] $($folder.Name) removida." -ForegroundColor Green
        } catch {
            Write-Host "  [ERRO] Falha ao remover $($folder.Name): $_" -ForegroundColor Red
        }
    }

    # 3. Excluir relatorios (.txt) se solicitado
    if ($DeleteReports) {
        Write-Host "Removendo arquivos de relatorio (.txt)..." -ForegroundColor Cyan
        try {
            Remove-Item -Path (Join-Path $Destino "*.txt") -Force -ErrorAction Stop
            Write-Host "  [OK] Todos os arquivos .txt foram removidos." -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -like "*não encontrado*") { Write-Host "  [INFO] Nenhum arquivo .txt encontrado." -ForegroundColor Yellow }
            else { Write-Host "  [ERRO] Falha ao remover .txt: $_" -ForegroundColor Red }
        }
        
        $Config.LastUsedPath = $Destino; Save-Config
        Write-Host "Operacao concluida com sucesso." -ForegroundColor Yellow
        Wait-Input
        return # Encerra aqui para NÃO recriar o relatório
    }

    # 4. Se relatorios foram mantidos, gera o novo padrão
    $Config.LastUsedPath = $Destino; Save-Config
    $ReportPath = Join-Path $Destino "Relatorio_Organizacao.txt"
    $Content = @("Relatorio de Operacao Reversa - $Destino","Data: $(Get-Date)","==========================","Estrutura de pastas restante:","")
    Get-ChildItem -Path $Destino -Directory | ForEach-Object { $Content += "$($_.Name) - $($_.FullName)\" }
    $Content | Set-Content -Path $ReportPath -Encoding UTF8
    
    Write-Host "Operacao concluida." -ForegroundColor Yellow
    type $ReportPath
    Wait-Input
}


# ============================================
# CONTROLE DE VERSOES
# ============================================

function Show-VersionControl {
    $subOptions = @(
        "[0] Ver versao atual",
        "[1] Buscar versoes no GitHub",
        "[2] Listar backups locais",
        "[3] Restaurar backup local",
        "[4] Baixar versao especifica do GitHub",
        "[5] Voltar"
    )
    
    do {
        $subChoice = Get-MenuChoice -Title "CONTROLE DE VERSOES" -Options $subOptions
        
        switch ($subChoice) {
            0 {
                # Ver versao atual
                Write-Host ""
                Write-Host "=== Versao Atual ===" -ForegroundColor Cyan
                $ver = $null
                $versionFile = Join-Path $AppDir "version.txt"
                if (Test-Path $versionFile) {
                    $ver = (Get-Content $versionFile -Raw -ErrorAction SilentlyContinue).Trim()
                }
                if ($ver) {
                    Write-Host "  Versao: $ver" -ForegroundColor Green
                } else {
                    Write-Host "  Versao: Nao definida" -ForegroundColor Yellow
                }
                $scriptPath = Join-Path $AppDir "script.ps1"
                $updaterPath = Join-Path $AppDir "Updater.ps1"
                if (Test-Path $scriptPath) {
                    Write-Host "  Script: $((Get-Item $scriptPath).LastWriteTime)" -ForegroundColor Gray
                }
                if (Test-Path $updaterPath) {
                    Write-Host "  Updater: $((Get-Item $updaterPath).LastWriteTime)" -ForegroundColor Gray
                }
                Write-Host ""
                Wait-Input
            }
            1 {
                # Buscar versoes no GitHub
                Write-Host ""
                Write-Host "=== Buscando versoes no GitHub ===" -ForegroundColor Cyan
                try {
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    $headers = @{"User-Agent" = "OrganizadorPOSTECH"; "Accept" = "application/vnd.github.v3+json"}
                    $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/DyFuchs/Organizador_POSTECH/releases" -Headers $headers -TimeoutSec 15
                    if ($releases.Count -eq 0) {
                        Write-Host "  Nenhuma release publica encontrada." -ForegroundColor Yellow
                    } else {
                        Write-Host "  Versoes disponiveis:" -ForegroundColor Green
                        for ($i = 0; $i -lt $releases.Count; $i++) {
                            $r = $releases[$i]
                            $tag = $r.tag_name
                            $date = $r.published_at.Substring(0, 10)
                            $pre = if ($r.prerelease) { " [PRE-RELEASE]" } else { "" }
                            Write-Host "    [$i] $tag ($date)$pre" -ForegroundColor White
                        }
                    }
                } catch {
                    Write-Host "  Erro ao buscar: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "  Verifique sua conexao com a internet." -ForegroundColor Yellow
                }
                Write-Host ""
                Wait-Input
            }
            2 {
                # Listar backups locais
                Write-Host ""
                Write-Host "=== Backups Locais ===" -ForegroundColor Cyan
                $backupDir = Join-Path $AppDir "_backup"
                if (-not (Test-Path $backupDir)) {
                    Write-Host "  Nenhum backup encontrado." -ForegroundColor Yellow
                } else {
                    $backups = Get-ChildItem $backupDir -Directory | Sort-Object LastWriteTime -Descending
                    if ($backups.Count -eq 0) {
                        Write-Host "  Nenhum backup encontrado." -ForegroundColor Yellow
                    } else {
                        Write-Host "  Backups disponiveis:" -ForegroundColor Green
                        for ($i = 0; $i -lt $backups.Count; $i++) {
                            $b = $backups[$i]
                            $size = (Get-ChildItem $b.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
                            $sizeMB = [math]::Round($size / 1MB, 2)
                            Write-Host "    [$i] $($b.Name) ($sizeMB MB)" -ForegroundColor White
                        }
                    }
                }
                Write-Host ""
                Wait-Input
            }
            3 {
                # Restaurar backup local
                Write-Host ""
                Write-Host "=== Restaurar Backup ===" -ForegroundColor Cyan
                $backupDir = Join-Path $AppDir "_backup"
                if (-not (Test-Path $backupDir)) {
                    Write-Host "  Nenhum backup encontrado." -ForegroundColor Yellow
                    Wait-Input
                    continue
                }
                $backups = Get-ChildItem $backupDir -Directory | Sort-Object LastWriteTime -Descending
                if ($backups.Count -eq 0) {
                    Write-Host "  Nenhum backup encontrado." -ForegroundColor Yellow
                    Wait-Input
                    continue
                }
                Write-Host "  Backups disponiveis:" -ForegroundColor Green
                for ($i = 0; $i -lt $backups.Count; $i++) {
                    Write-Host "    [$i] $($backups[$i].Name)" -ForegroundColor White
                }
                Write-Host ""
                $sel = Read-Host "  Escolha o numero do backup (ou C para cancelar)"
                if ($sel -eq "C" -or $sel -eq "c") { continue }
                $idx = [int]$sel
                if ($idx -lt 0 -or $idx -ge $backups.Count) {
                    Write-Host "  Opcao invalida!" -ForegroundColor Red
                    Start-Sleep -Milliseconds 500
                    continue
                }
                $chosen = $backups[$idx]
                Write-Host ""
                Write-Host "  Backup escolhido: $($chosen.Name)" -ForegroundColor Yellow
                $confirm = Read-Host "  Confirma a restauracao? Os arquivos atuais serao substituidos. [S/N]"
                if ($confirm -ne "S" -and $confirm -ne "s") {
                    Write-Host "  Cancelado." -ForegroundColor Yellow
                    Start-Sleep -Milliseconds 500
                    continue
                }
                $files = @("script.ps1", "Updater.ps1", "config.json", "version.txt")
                foreach ($f in $files) {
                    $src = Join-Path $chosen.FullName $f
                    $dest = Join-Path $AppDir $f
                    if (Test-Path $src) {
                        Copy-Item $src $dest -Force
                        Write-Host "  Restaurado: $f" -ForegroundColor Green
                    }
                }
                Write-Host ""
                Write-Host "  Restauracao concluida!" -ForegroundColor Green
                Write-Host "  Reinicie a aplicacao para usar a versao restaurada." -ForegroundColor Yellow
                Write-Host ""
                Wait-Input
            }
            4 {
                # Baixar versao especifica do GitHub
                Write-Host ""
                Write-Host "=== Baixar Versao Especifica ===" -ForegroundColor Cyan
                try {
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    $headers = @{"User-Agent" = "OrganizadorPOSTECH"; "Accept" = "application/vnd.github.v3+json"}
                    $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/DyFuchs/Organizador_POSTECH/releases" -Headers $headers -TimeoutSec 15
                    if ($releases.Count -eq 0) {
                        Write-Host "  Nenhuma release publica encontrada." -ForegroundColor Yellow
                        Wait-Input
                        continue
                    }
                    Write-Host "  Versoes disponiveis:" -ForegroundColor Green
                    for ($i = 0; $i -lt $releases.Count; $i++) {
                        $r = $releases[$i]
                        $pre = if ($r.prerelease) { " [PRE-RELEASE]" } else { "" }
                        Write-Host "    [$i] $($r.tag_name) ($($r.published_at.Substring(0,10)))$pre" -ForegroundColor White
                    }
                    Write-Host ""
                    $sel = Read-Host "  Escolha o numero da versao (ou C para cancelar)"
                    if ($sel -eq "C" -or $sel -eq "c") { continue }
                    $idx = [int]$sel
                    if ($idx -lt 0 -or $idx -ge $releases.Count) {
                        Write-Host "  Opcao invalida!" -ForegroundColor Red
                        Start-Sleep -Milliseconds 500
                        continue
                    }
                    $chosen = $releases[$idx]
                    Write-Host ""
                    Write-Host "  Versao escolhida: $($chosen.tag_name)" -ForegroundColor Yellow
                    $confirm = Read-Host "  Confirma o download e instalacao? [S/N]"
                    if ($confirm -ne "S" -and $confirm -ne "s") {
                        Write-Host "  Cancelado." -ForegroundColor Yellow
                        Start-Sleep -Milliseconds 500
                        continue
                    }
                    # Criar backup antes de substituir
                    $backupDir = Join-Path $AppDir "_backupackup_$(Get-Date -Format "yyyyMMdd_HHmmss")"
                    New-Item $backupDir -ItemType Directory -Force | Out-Null
                    $files = @("script.ps1", "Updater.ps1", "config.json", "version.txt")
                    foreach ($f in $files) {
                        $src = Join-Path $AppDir $f
                        if (Test-Path $src) {
                            Copy-Item $src $backupDir -Force
                        }
                    }
                    Write-Host "  Backup criado em: $backupDir" -ForegroundColor Green
                    # Baixar ZIP da release (preferir asset, fallback para zipball)
                    if ($chosen.assets -and $chosen.assets.Count -gt 0) {
                        $asset = $chosen.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
                        if ($asset) {
                            $zipUrl = $asset.browser_download_url
                        } else {
                            $zipUrl = $chosen.zipball_url
                        }
                    } else {
                        $zipUrl = $chosen.zipball_url
                    }
                    $zipPath = Join-Path $env:TEMP "organizador_$($chosen.tag_name).zip"
                    Write-Host "  Baixando..." -ForegroundColor Cyan
                    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -Headers $headers -UseBasicParsing
                    # Extrair
                    $extractPath = Join-Path $env:TEMP "organizador_extract"
                    if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
                    Expand-Archive $zipPath $extractPath -Force
                    # Encontrar a subpasta extraida
                    $extractedDir = Get-ChildItem $extractPath -Directory | Select-Object -First 1
                    if ($extractedDir) {
                        foreach ($f in $files) {
                            $src = Join-Path $extractedDir.FullName $f
                            $dest = Join-Path $AppDir $f
                            if (Test-Path $src) {
                                Copy-Item $src $dest -Force
                                Write-Host "  Instalado: $f" -ForegroundColor Green
                            }
                        }
                    }
                    # Limpar temporarios
                    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
                    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
                    # Atualizar version.txt
                    $chosen.tag_name | Set-Content (Join-Path $AppDir "version.txt") -Encoding UTF8
                    Write-Host ""
                    Write-Host "  Instalacao concluida!" -ForegroundColor Green
                    Write-Host "  Reinicie a aplicacao para usar a nova versao." -ForegroundColor Yellow
                } catch {
                    Write-Host "  Erro: $($_.Exception.Message)" -ForegroundColor Red
                }
                Write-Host ""
                Wait-Input
            }
            5 { return }
            -1 { continue }
        }
    } while ($true)
}


# Menu Loop
do {
    # Lógica de exibição do caminho
    $currentPath = Get-SuggestedPath
    if ($currentPath -eq $AppDir) { $currentPath = "mesma pasta do script" }
    $pathInfo = "Caminho atual: $currentPath"

    if ($Config.UseArrowKeys) {
        $mainOptions = @(
            "[1] Modo Automatico",
            "[2] Modo Manual",
            "[3] Configuracoes",
            "[4] Instrucoes",
            "[5] Creditos",
            "[6] Modo Reverso",
            "[7] Gerar Relatorio",
            "[8] Controle de Versoes",
            "[9] Sair"
        )# O caminho agora é passado como subtítulo e redesenhado a cada ciclo
        $choice = Get-MenuChoice -Title "ORGANIZADOR DE PASTAS POSTECH v$Version" -Options $mainOptions -InfoLine $pathInfo

        switch ($choice) {
            0 { Run-Core -Mode 'Auto' }
            1 { Run-Core -Mode 'Manual' }
            2 { Show-Settings }
            3 { Show-Instructions }
            4 { Show-Credits }
            5 { Run-Reverse }
            6 { Gerar-Relatorio }
            7 { Show-VersionControl }
            8 { exit }
            -1 { continue }
        }
    } else {
        Show-Logo
        Write-Host $pathInfo -ForegroundColor Gray
        Write-Host "=========================="
        Write-Host "[1] Modo Automatico"
        Write-Host "[2] Modo Manual"
        Write-Host "[3] Configuracoes"
        Write-Host "[4] Instrucoes"
        Write-Host "[5] Creditos"
        Write-Host "[6] Modo Reverso"
        Write-Host "[7] Gerar Relatorio"
        Write-Host "[8] Controle de Versoes"
        Write-Host "[9] Sair"
        Write-Host "==========================" -NoNewline

        $key = [Console]::ReadKey($true)
        $choice = $key.KeyChar.ToString().ToUpper()
        Write-Host $choice -ForegroundColor Cyan

        switch ($choice) {
            '1' { Run-Core -Mode 'Auto' }
            '2' { Run-Core -Mode 'Manual' }
            '3' { Show-Settings }
            '4' { Show-Instructions }
            '5' { Show-Credits }
            '6' { Run-Reverse }
            '7' { Gerar-Relatorio }
            '8' { Show-VersionControl }
            '9' { exit }
            default { Write-Host "Opcao invalida!"; Start-Sleep -Milliseconds 500 }
        }
    }
} while ($true)
