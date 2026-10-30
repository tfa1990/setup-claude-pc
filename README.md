# setup-claude-pc

Instala num Windows novo os programas, skills, agentes, plugins e servidores MCP que uso com o Claude Code.
Não contém dados pessoais, memórias, conversas nem tokens. As skills de terceiros não ficam aqui:
o instalador baixa cada uma do repositório original, no commit listado em `fontes.json`.

## Instalar (sem login no GitHub)

Abra o PowerShell e rode:

```powershell
$d="$env:USERPROFILE\setup-claude-pc"; Invoke-WebRequest https://codeload.github.com/tfa1990/setup-claude-pc/zip/main -OutFile "$d.zip"; Expand-Archive "$d.zip" $env:USERPROFILE -Force; Rename-Item "$env:USERPROFILE\setup-claude-pc-main" $d -EA SilentlyContinue; powershell -NoProfile -ExecutionPolicy Bypass -File "$d\instalar.ps1"
```

Ou, num Claude já instalado no PC novo, peça:

> Baixe github.com/tfa1990/setup-claude-pc (é público), siga o LEIA-ME-CLAUDE.md e instale meu ambiente.

## O que fica de fora

- Pacotes pagos ou de curso (licença não permite repositório público): instale pela compra.
- Login do Claude, autorização dos MCP, chaves de API e licenças de programas.

## Atualizar o kit

No PC de origem: `gerar-kit.ps1`, revisar o `git diff`, commit e push.
