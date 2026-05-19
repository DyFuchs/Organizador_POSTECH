📄 Guia de Instalação - Organizador de Arquivos POSTECH
O Organizador de Arquivos POSTECH é uma ferramenta automatizada para organizar vídeos de aulas e materiais de curso da FIAP/POSTECH, criando subpastas estruturadas automaticamente.

Esta ferramenta foi projetada para rodar em ambientes Windows empresariais, não requer privilégios de administrador e não necessita de instalação de softwares externos.

🚀 Instalação Rápida (Via Terminal)
A maneira mais rápida de instalar a aplicação é através de um único comando. Este comando baixa a versão mais recente do GitHub e inicia o assistente de instalação.

Passo a Passo:
Abra a pasta onde você deseja que o programa seja instalado.
Clique na barra de endereços da pasta, digite cmd e aperte Enter. Isso abrirá o Prompt de Comando já no local correto.
Copie e cole o comando abaixo e aperte Enter:
powershell

'powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $content = Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/DyFuchs/Organizador_POSTECH/main/Organizador_POSTECH_Instalador.bat' -UserAgent 'OrganizadorPOSTECH'; [System.IO.File]::WriteAllText(\"$env:TEMP\Organizador_POSTECH_Instalador.bat\", $content.Content, [System.Text.Encoding]::ASCII); $env:INSTALL_PATH = $pwd; Start-Process \"$env:TEMP\Organizador_POSTECH_Instalador.bat\""'

🛠️ Como funciona o Instalador?
Assim que você rodar o comando acima, o Assistente de Instalação será iniciado:

Definição do Local: O instalador sugerirá a pasta onde você abriu o CMD.
Se estiver correto, basta apertar Enter.
Se quiser instalar em outro lugar, digite ou cole o caminho completo da pasta.
Download: O assistente baixará os arquivos necessários (script.ps1, Updater.ps1, config.json e version.txt) diretamente do repositório oficial.
Finalização: O instalador criará automaticamente um atalho na sua Área de Trabalho chamado Organizador POSTECH.
📂 Estrutura da Aplicação
Após a instalação, a pasta do programa conterá:

Iniciar Organizador POSTECH.bat $\rightarrow$ Use este arquivo para abrir o programa.
script.ps1 $\rightarrow$ O motor principal da aplicação.
Updater.ps1 $\rightarrow$ Responsável por manter a ferramenta atualizada.
config.json $\rightarrow$ Onde ficam salvas as suas preferências.

❓ Perguntas Frequentes (FAQ)
🛡️ É seguro? Preciso de administrador?
Sim, é seguro. O script utiliza apenas comandos nativos do Windows (PowerShell e Batch). Não é necessário ser administrador para instalar ou rodar a ferramenta, pois ela opera inteiramente dentro da sua pasta de usuário.

⚠️ O comando deu erro de "Execution Policy"?
Não se preocupe. O inicializador (.bat) já foi configurado para contornar a política de execução do PowerShell (-ExecutionPolicy Bypass) apenas para a sessão do programa, garantindo que ele funcione mesmo em máquinas com restrições de segurança.

📁 Onde ficam meus arquivos organizados?
A aplicação organiza os arquivos na pasta que você definiu durante a instalação ou na pasta que você selecionar ao abrir o programa no "Modo Manual".

🔄 Como atualizar a ferramenta?
O programa possui um sistema de auto-update. Ao iniciar, ele verifica se existe uma versão mais recente no GitHub e oferece a atualização automaticamente.

🤝 Suporte
Se encontrar algum erro durante a instalação, certifique-se de que possui conexão com a internet e que o caminho da pasta não contenha caracteres proibidos como < > | ? *.
