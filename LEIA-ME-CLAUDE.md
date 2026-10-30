# Instruções para o Claude do computador novo

Este repositório público instala o ambiente de trabalho do usuário num Windows novo.
Fale sempre em português do Brasil.

1. Baixar sem login (o repositório é público):
   ```powershell
   $d="$env:USERPROFILE\setup-claude-pc"
   Invoke-WebRequest https://codeload.github.com/tfa1990/setup-claude-pc/zip/main -OutFile "$d.zip"
   Expand-Archive "$d.zip" $env:USERPROFILE -Force
   Rename-Item "$env:USERPROFILE\setup-claude-pc-main" $d -EA SilentlyContinue
   ```
   Se a pasta já existir, apagar só `setup-claude-pc-main` antes de renomear.

2. Rodar o instalador em segundo plano (demora; o winget abre instaladores):
   `powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\setup-claude-pc\instalar.ps1"`
   Pode rodar de novo sem problema; ele faz backup de `~\.claude` antes.

3. Ler a saída inteira. Corrigir o que estiver em "Itens que falharam"
   (ex.: plugin com outro nome no marketplace, pacote winget indisponível). Não inventar sucesso.

4. Guiar o usuário, um passo por vez, no "FALTA FAZER À MÃO": login no Claude, `/mcp`,
   Ghidra para o MCP rea, pacotes pagos, licenças e chaves de API.

5. Pedir para reiniciar o app Claude e conferir: `claude plugin list`, `claude mcp list`,
   `ffmpeg -version`, `node -v`, `uv --version`, e se as skills edvid e remotion-best-practices aparecem.

Regras: nunca digitar senhas ou tokens (o usuário cola); nunca apagar backups.
