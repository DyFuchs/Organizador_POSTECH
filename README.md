
```markdown
# Organizador de Pastas POSTECH

[![Version](https://img.shields.io/github/v/release/DyFuchs/Organizador_POSTECH)](https://github.com/DyFuchs/Organizador_POSTECH/releases)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

Ferramenta de automação em PowerShell para organização inteligente de vídeos acadêmicos e corporativos,
desenvolvida para padronizar a estrutura de pastas de cursos da FIAP/POSTECH.

## 📋 Índice

- [Sobre](#-sobre)
- [Funcionalidades](#-funcionalidades)
- [Requisitos](#-requisitos)
- [Instalação](#-instalação)
- [Primeiros Passos](#-primeiros-passos)
- [Modos de Operação](#-modos-de-operação)
- [Configurações](#-configurações)
- [Sistema de Atualização](#-sistema-de-atualização)
- [Estrutura de Arquivos](#-estrutura-de-arquivos)
- [Relatórios](#-relatórios)
- [Solução de Problemas](#-solução-de-problemas)
- [Contribuição](#-contribuição)
- [Licença](#-licença)

## 📖 Sobre

O **Organizador de Pastas POSTECH** automatiza o processo de organização de vídeos de cursos,
eliminando o trabalho manual repetitivo e garantindo padronização na estrutura de diretórios.
A ferramenta detecta automaticamente padrões de nomenclatura nos arquivos de vídeo
e os organiza em pastas correspondentes, gerando relatórios detalhados
com duração e localização de cada arquivo.

### Casos de Uso
- Organização de materiais de cursos EAD (Ensino a Distância)
- Padronização de repositórios de vídeo corporativos
- Auditoria de conteúdo multimídia com métricas de duração
- Gestão de bibliotecas de vídeo para plataformas de ensino

## ✨ Funcionalidades

### Organização Inteligente
- **Detecção Automática**: Identifica padrões como "Aula N",
"Boas Vindas" nos nomes dos arquivos
- **Múltiplos Formatos**: Suporta MP4, MKV, AVI, MOV, WMV, FLV, WEBM
- **Criação Automática**: Gera pastas numeradas (Aula 1, Aula 2, etc.)
e pastas extras (Capítulo de Projeto, Onboarding)
- **Modo Reverso**: Desfaz a organização, movendo vídeos de
volta para a raiz e limpando pastas

### Relatórios Detalhados
- **Duração por Vídeo**: Extrai metadados nativos do Windows sem software externo
- **Duração Total**: Soma o tempo total em HH:MM:SS e minutos decimais
- **Duração por Pasta**: Agrega o tempo de cada capítulo/aula
- **Mapeamento de Rede**: Converte caminhos UNC (\\IP\) para unidades mapeadas (T:\)
- **Versionamento**: Gera relatórios numerados
automaticamente (Relatorio_Organizacao (1).txt, (2).txt...)

### Interface Flexível
- **Navegação por Teclas**: Seleção instantânea (sem precisar pressionar Enter)
- **Navegação por Setas**: Modo opcional com cursor visual e destaque
- **Cores Semânticas**: Verde (sucesso), Vermelho (erro), Amarelo (aviso), Ciano (títulos)
- **Totalmente em Português**: Interface e documentação em português do Brasil

### Sistema de Atualização
- **Auto-Update**: Verifica automaticamente novas versões no GitHub Releases
- **Confirmação do Usuário**: Pergunta antes de atualizar
- **Backup Automático**: Salva versão anterior antes de atualizar
- **Rollback Fácil**: Permite restaurar versão anterior a partir do backup

## 📋 Requisitos

### Mínimos
- **Sistema Operacional**: Windows 10/11 ou Windows Server 2016+
- **PowerShell**: Versão 5.1 ou superior (já incluso no Windows 10/11)
- **.NET Framework**: 4.5 ou superior
- **Espaço em Disco**: 10 MB para a aplicação + espaço para os vídeos
- **Conexão Internet**: Necessária apenas para download inicial e atualizações

### Opcionais
- **Git**: Recomendado para instalação e atualização via repositório
- **Acesso de Leitura/Escrita**: Na pasta de destino dos vídeos

## 🚀 Instalação

### Método 1: Via Git (Recomendado)

Este método permite atualizações fáceis com `git pull`.

1. **Instale o Git** (se ainda não tiver):
   - Baixe em: https://git-scm.com/download/win
   - Execute o instalador com as opções padrão

2. **Clone o repositório**:
   ```bash
   # Abra o PowerShell ou CMD na pasta desejada
   git clone https://github.com/DyFuchs/Organizador_POSTECH.git "Organizador Postech"
   
   # Entre na pasta
   cd "Organizador Postech"
   ```

3. **Execute o instalador**:
   ```bash
   # Execute o script de instalação
   .\Install.bat
   ```

4. **Para atualizar no futuro**:
   ```bash
   cd "Organizador Postech"
   git pull
   ```

### Método 2: Instalador Automático (Sem Git)

Ideal para usuários que não desejam instalar o Git.

1. **Baixe o instalador**:
   - Baixe o arquivo `Install.bat` e `Install_NoGit.ps1` para uma pasta
   - Ou execute diretamente do repositório

2. **Execute o instalador**:
   ```bash
   .\Install.bat
   ```
   Ou, se não tiver Git:
   ```bash
   powershell -ExecutionPolicy Bypass -File .\Install_NoGit.ps1
   ```

3. **Siga as instruções na tela**:
   - Escolha a pasta de instalação (ou pressione Enter para usar a atual)
   - Aguarde o download e extração automática
   - Ao final, o instalador oferece abrir a pasta

### Método 3: Download Manual

1. **Baixe a última versão**:
   - Acesse: https://github.com/DyFuchs/Organizador_POSTECH/releases
   - Baixe o arquivo `Organizador_de_Pastas_POSTECH-X.Y.Z.zip`
   - Extraia em uma pasta de sua preferência

2. **Primeira execução**:
   - Navegue até a pasta extraída
   - Execute `Launch.bat` (ou renomeie para "Iniciar Organizador POSTECH.bat")

## 🎯 Primeiros Passos

### Configuração Inicial

Após a instalação, execute o `Launch.bat`. Na primeira execução:

1. **Menu Principal** será exibido com as opções:
   ```
   [1] Modo Automatico
   [2] Modo Manual
   [3] Configuracoes
   [4] Instrucoes
   [5] Creditos
   [6] Modo Reverso
   [7] Gerar Relatorio
   [8] Sair
   ```

2. **Configure as preferências** (opcional):
   - Pressione `[3]` para acessar Configurações
   - Ajuste as opções conforme necessário
     (veja seção [Configurações](#-configurações))
   - Pressione `[9]` para voltar ao menu principal

3. **Organize seus vídeos**:
   - Pressione `[1]` para Modo Automático (recomendado para iniciantes)
   - Ou `[2]` para Modo Manual (controle total)

### Estrutura Recomendada de Pastas

Antes de organizar, sua pasta deve conter:
```
📁 Videos_Curso/
├── Aula 1 - Introducao.mp4
├── Aula 2 - Conceitos Basicos.mp4
├── Aula 10 - Projeto Final.mp4
├── Boas Vindas.mp4
└── Material_Extras.mp4
```

Após organização:
```
📁 Videos_Curso/
├── 📁 Aula 1/
│   └── Aula 1 - Introducao.mp4
├── 📁 Aula 2/
│   └── Aula 2 - Conceitos Basicos.mp4
├── 📁 Aula 10/
│   └── Aula 10 - Projeto Final.mp4
├── 📁 Capitulo de Projeto/
│   └── Boas Vindas.mp4
├──  Onboarding/
── Relatorio_Organizacao.txt
```

## 🔧 Modos de Operação

### 1. Modo Automático

**Ideal para**: Organização rápida sem intervenção manual.

**Como funciona**:
- Detecta automaticamente o caminho mais recente ou padrão
- Identifica o número máximo de aulas baseado nos arquivos
- Cria pastas e move os vídeos automaticamente
- Gera relatório final

**Padrões de Detecção**:
- `Aula N` → Pasta "Aula N" (ex: "Aula 5.mp4" → pasta "Aula 5")
- `Boas Vindas` → Pasta "Capítulo de Projeto"
  (aceita: "boas-vindas", "boas_vindas", "boas vindas")
- Outros vídeos → Permanecem na raiz

**Execução**:
```
Menu Principal → [1] Modo Automatico
```

### 2. Modo Manual

**Ideal para**: Controle total sobre o processo de organização.

**Opções configuráveis**:
- **Caminho de Destino**: Escolha a pasta onde os vídeos estão localizados
- **Quantidade de Aulas**: Defina manualmente quantas pastas "Aula N" criar
- **Pastas Extras**: Decida se cria "Capítulo de Projeto" e "Onboarding"

**Execução**:
```
Menu Principal → [2] Modo Manual
```

**Fluxo**:
1. Informe o caminho (ou use a sugestão)
2. Confirme ou altere a quantidade de aulas
3. Responda se deseja criar pastas extras (S/N)
4. Confirme a execução (S/N)

### 3. Modo Reverso

**Ideal para**: Desfazer a organização ou reorganizar de forma diferente.

**O que faz**:
- Move todos os vídeos das pastas "Aula N", "Capítulo de Projeto"
  e "Onboarding" de volta para a raiz
- Exclui as pastas vazias
- Opcionalmente, remove os relatórios `.txt` existentes

**Atenção**: Esta ação não pode ser desfeita automaticamente. 
Certifique-se de ter backup se necessário.

**Execução**:
```
Menu Principal → [6] Modo Reverso
```

### 4. Gerar Relatório

**Ideal para**: Auditoria sem modificar a estrutura de pastas.

**O que faz**:
- Varre recursivamente todas as pastas
- Extrai duração de cada vídeo
- Gera relatório completo sem mover arquivos
- Cria versão numerada se já existir relatório

**Execução**:
```
Menu Principal → [7] Gerar Relatorio
```

## ⚙️ Configurações

Acesse o menu de configurações pressionando `[3]` no menu principal.

### Opções Disponíveis

#### [0] Atualização Automática
- **Padrão**: Desligado (OFF)
- **Função**: Verifica automaticamente novas versões no GitHub ao iniciar
- **Recomendado**: Ligado para receber atualizações de segurança e melhorias

#### [1] Pedido de Confirmação
- **Padrão**: Habilitado (ON)
- **Função**: Solicita confirmação [S/N] antes de executar operações
- **Recomendado**: Habilitado para evitar execuções acidentais

#### [2] Pastas Extras Automáticas
- **Padrão**: Habilitado (ON)
- **Função**: Cria automaticamente pastas "Capítulo de Projeto" e "Onboarding"
- **Recomendado**: Habilitado para cursos que possuem vídeos de boas-vindas

#### [3] Auto-Preenchimento
- **Padrão**: Habilitado (ON)
- **Função**: Sugere valores baseados na última execução ou detecção automática
- **Recomendado**: Habilitado para agilizar o Modo Manual

#### [4] Definir Caminho de Origem Fixo
- **Função**: Define um caminho padrão para origem dos vídeos
- **Prioridade**: Usado se "Destino Fixo" estiver vazio
- **Exemplo**: `T:\Cursos\IA\Videos`

#### [5] Definir Caminho de Destino Fixo
- **Função**: Define um caminho padrão para organização
- **Prioridade**: Máxima (sobrescreve todas as outras sugestões)
- **Exemplo**: `T:\Cursos\IA\Videos_Finalizados`

#### [6] Limpar Caminhos Fixos
- **Função**: Remove os caminhos de origem e destino fixos
- **Resultado**: Volta a usar sugestões automáticas

#### [7] Limpar Último Caminho Utilizado
- **Função**: Limpa o histórico do último caminho usado
- **Quando usar**: Ao mudar de projeto ou curso

#### [8] Navegação por Setas
- **Padrão**: Desabilitado (OFF)
- **Função**: Alterna entre navegação por teclas instantâneas
  e navegação por cursor com setas
- **Recomendado**: Desabilitado para usuários experientes (mais rápido)

#### [9] Voltar ao Menu Principal
- Retorna ao menu principal sem salvar alterações
  (as alterações são salvas automaticamente ao mudar cada opção)

### Hierarquia de Caminhos

O sistema usa a seguinte ordem de prioridade para sugerir caminhos:

1. **Caminho de Destino Fixo** (se definido)
2. **Caminho de Origem Fixo** (se definido)
3. **Último Caminho Utilizado** (salvo automaticamente)
4. **Pasta Atual** (onde o script foi executado)

### Arquivo de Configuração

As configurações são salvas em `config.json` na pasta da aplicação:

```json
{
  "ConfirmReq": true,
  "AutoExtra": true,
  "AutoFill": true,
  "FixedSource": "",
  "FixedDest": "T:\\Cursos\\IA\\Videos",
  "LastUsedPath": "T:\\Cursos\\IA\\Videos",
  "UseArrowKeys": false,
  "AutoUpdate": true
}
```

**Edição Manual**: Você pode editar este arquivo com o Bloco de Notas, 
mas certifique-se de manter a sintaxe JSON válida.

## 🔄 Sistema de Atualização

### Atualização Automática

Quando habilitada (`AutoUpdate = true`), o sistema:

1. **Verifica** o GitHub Releases ao iniciar (via `Launch.bat`)
2. **Compara** a versão local com a versão mais recente
3. **Pergunta** se deseja atualizar (se houver versão nova)
4. **Cria Backup** da versão atual em `_backup\backup_vX.Y.Z_YYYYMMDD_HHMMSS\`
5. **Baixa** o ZIP da nova versão
6. **Extrai** e substitui os arquivos
7. **Atualiza** o `version.txt`

#### Via Releases
1. Acesse: https://github.com/DyFuchs/Organizador_POSTECH/releases
2. Baixe o ZIP da versão mais recente
3. Extraia sobre a pasta atual (ou faça backup primeiro)

### Sistema de Backup

**Localização**: `_backup\`

**Conteúdo**: Todos os arquivos da pasta raiz são copiados:
- `script.ps1`
- `Updater.ps1`
- `Launch.bat`
- `config.json`
- `version.txt`
- Quaisquer outros arquivos `.ps1`, `.bat`, `.json`, `.txt`

**Nomeação**: `backup_vX.Y.Z_YYYYMMDD_HHMMSS`
- Exemplo: `backup_v1.2.0_20260519_143022`

**Restauração**: Para restaurar um backup:
1. Feche a aplicação
2. Copie os arquivos da pasta de backup para a pasta raiz
3. Substitua quando solicitado

## 📁 Estrutura de Arquivos

### Após Instalação

```
Organizador Postech/
├── Launch.bat                    # Launcher principal (execute este)
├── script.ps1                    # Aplicação principal
├── Updater.ps1                   # Sistema de atualização
├── config.json                   # Configurações (gerado na 1ª execução)
├── version.txt                   # Versão atual
├── Install.bat                   # Instalador (Git)
├── Install_NoGit.ps1             # Instalador (sem Git)
├── README.md                     # Documentação
├── LICENSE                       # Licença MIT
├── _backup/                      # Backups automáticos
│   ├── backup_v1.0.0_20260519_120000/
│   └── backup_v1.1.0_20260519_140000/
└── Videos_Curso/                 # Exemplo de pasta de vídeos (opcional)
    ├── Aula 1/
    ├── Aula 2/
    └── Relatorio_Organizacao.txt
```

### Arquivos Temporários

Durante a atualização, arquivos temporários são criados em:
- `%TEMP%\postech_update.zip` (ZIP baixado)
- `%TEMP%\postech_update_tmp\` (extração temporária)

Estes arquivos são automaticamente removidos após a atualização.

## 📊 Relatórios

### Formato do Relatório

O relatório é gerado em `Relatorio_Organizacao.txt` com a seguinte estrutura:

```
RELATORIO DE ORGANIZACAO
Destino: T:\Cursos\IA\Videos
Data: 19/05/2026 14:30:22
============================================================
ESTRUTURA DE PASTAS:
  Aula 1 - T:\Cursos\IA\Videos\Aula 1\
  Aula 2 - T:\Cursos\IA\Videos\Aula 2\
  Capitulo de Projeto - T:\Cursos\IA\Videos\Capitulo de Projeto\

============================================================
TODOS OS VIDEOS:

[Aula 1] Aula_1_Introducao.mp4
  Duracao: 00:45:30
  Caminho: T:\Cursos\IA\Videos\Aula 1\Aula_1_Introducao.mp4

[Aula 2] Aula_2_Conceitos.mp4
  Duracao: 01:15:00
  Caminho: T:\Cursos\IA\Videos\Aula 2\Aula_2_Conceitos.mp4

[Capitulo de Projeto] Boas_Vindas.mp4
  Duracao: 00:05:20
  Caminho: T:\Cursos\IA\Videos\Capitulo de Projeto\Boas_Vindas.mp4

============================================================
DURACAO POR PASTA:
  [Aula 1] 00:45:30 (45.50 min)
  [Aula 2] 01:15:00 (75.00 min)
  [Capitulo de Projeto] 00:05:20 (5.33 min)

============================================================
RESUMO DE DURACAO TOTAL:
  Tempo Total: 02:05:50
  Equivalente a: 125.83 minutos
============================================================
```

### Formatação de Rede

Se o caminho for uma rede corporativa, o relatório converte automaticamente:

**Entrada**: `\\192.168.62.17\postech$\IAST - AI Scientist\2026.1 - 1IAST\Fase 3\...`

**Saída no Relatório**: `T:\IAST - AI Scientist\2026.1 - 1IAST\Fase 3\...`

Isso segue o padrão de mapeamento da FIAP/POSTECH.

### Versionamento de Relatórios

Se já existir um relatório, o sistema cria versões numeradas:
- `Relatorio_Organizacao.txt` (primeiro)
- `Relatorio_Organizacao (1).txt` (segundo)
- `Relatorio_Organizacao (2).txt` (terceiro)
- E assim por diante...

## 🛠️ Solução de Problemas

### Problemas Comuns

#### "PowerShell não é reconhecido como um comando"

**Solução**:
1. Verifique se o PowerShell está instalado (Windows 10/11 já incluem)
2. Adicione o PowerShell ao PATH do sistema
3. Reinicie o terminal

#### "Acesso negado ao executar script.ps1"

**Solução**:
```powershell
# Execute no PowerShell como Administrador
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

Ou execute via `Launch.bat` que já contorna essa restrição.

#### "Duração dos vídeos aparece como 00:00:00"

**Causa**: O Windows ainda não indexou os metadados do arquivo.

**Solução**:
1. Aguarde alguns minutos (o Windows Explorer precisa indexar)
2. Copie os vídeos para uma pasta local temporária
3. Abra o vídeo no Windows Media Player por alguns segundos
4. Execute a organização novamente

#### "Erro 404 ao verificar atualizações"

**Causa**: Cache do GitHub ou repositório privado.

**Solução**:
1. Verifique se o repositório está público
2. Aguarde 10-15 minutos (cache do GitHub)
3. Execute manualmente: `.\Updater.ps1 -Force`

#### "Arquivos não são movidos para as pastas"

**Verifique**:
1. Os nomes dos vídeos seguem o padrão? (ex: "Aula 1.mp4", "Aula_2.mp4")
2. Você tem permissão de escrita na pasta de destino?
3. Os arquivos não estão abertos em outro programa?

#### "Relatório quebra linhas no Bloco de Notas"

**Solução**:
1. Use Word Wrap: Formatar > Quebra Automática de Linha
2. Ou use editores como VS Code, Notepad++ ou WordPad

### Logs e Debug

Para diagnosticar problemas, execute:

```powershell
# Modo debug do Updater
.\Updater.ps1 -Debug

# Verificar versão no GitHub
powershell -Command "Invoke-RestMethod https://api.github.com/repos/DyFuchs/Organizador_POSTECH/releases | Select-Object -First 1"

# Verificar arquivos na pasta
Get-ChildItem -Path . -Recurse | Select-Object FullName
```

### Suporte

Se o problema persistir:
1. Verifique os [Issues](https://github.com/DyFuchs/Organizador_POSTECH/issues) existentes
2. Crie um novo issue com:
   - Versão do Windows
   - Versão do PowerShell (`$PSVersionTable.PSVersion`)
   - Mensagem de erro completa
   - Passos para reproduzir

## 🤝 Contribuição

Contribuições são bem-vindas! Para contribuir:

1. **Fork** o repositório
2. **Crie uma branch** para sua feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. **Push** para a branch (`git push origin feature/AmazingFeature`)
5. **Abra um Pull Request**

### Padrões de Código
- Use **PowerShell 5.1+**
- Siga as [Melhores Práticas do PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/vscode/using-vscode?view=powershell-7.2)
- Comente funções complexas
- Mantenha compatibilidade com Windows 10/11

### Reportar Bugs
- Use o [GitHub Issues](https://github.com/DyFuchs/Organizador_POSTECH/issues)
- Descreva o problema detalhadamente
- Inclua passos para reproduzir
- Anexe logs ou screenshots se aplicável

### Solicitar Features
- Discuta a feature em uma issue antes de implementar
- Explique o caso de uso
- Descreva o comportamento esperado

## 📄 Licença

Distribuído sob a licença **MIT**. Veja `LICENSE` para mais informações.

Este projeto é desenvolvido por **Diana Fuchs Santos** para FIAP/POSTECH a partir de Maio/2026.

---

## 📞 Contato

**Desenvolvedora**: Diana Fuchs Santos  
**Repositório**: https://github.com/DyFuchs/Organizador_POSTECH  
**Instituição**: FIAP/POSTECH

---

<div align="center">
  <strong>⬆️ <a href="#organizador-de-pastas-postech">Voltar ao topo</a> ⬆️</strong>
</div>
```
