# instalar.ps1
# Prepara um computador novo com os programas, skills, agentes, plugins e MCP do Claude.
# Não precisa de login no GitHub: tudo vem de repositórios públicos.
# Pode rodar de novo sem problema: o que já existe é atualizado.

# -SoSkills: refaz só skills e agentes (passos 4 e 5), útil para testar numa pasta vazia
param([switch]$SoSkills, [string]$ClaudeDir = (Join-Path $env:USERPROFILE '.claude'))

$ErrorActionPreference = 'Continue'
$kit    = Split-Path -Parent $MyInvocation.MyCommand.Path
$claude = $ClaudeDir
$homeFwd = $env:USERPROFILE.Replace('\', '/')
$utf8   = New-Object Text.UTF8Encoding $false
$falhas = New-Object System.Collections.Generic.List[string]

function AtualizarPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
                (Join-Path $env:APPDATA 'npm')
}
function ComHome([string]$t) { $t.Replace('{{HOME}}', $homeFwd) }
function Copiar($de, $para) { robocopy $de $para /E /NFL /NDL /NJH /NJS /NP | Out-Null }
function MontarRemotion([string]$raiz) {
    $sk = Join-Path $raiz 'skills'
    Copiar (Join-Path $sk 'remotion-best-practices') $raiz
    Get-ChildItem $sk -Directory -Filter 'remotion-*' | Where-Object Name -ne 'remotion-best-practices' | ForEach-Object {
        Copiar $_.FullName (Join-Path $raiz $_.Name)
    }
}

if (-not $SoSkills) {
Write-Host '1/8 Programas via winget (demora; janelas de instalação podem abrir)'
winget import -i (Join-Path $kit 'programas\winget.json') --accept-package-agreements --accept-source-agreements --ignore-unavailable
AtualizarPath

Write-Host '2/8 Pacotes npm globais (inclui Claude Code) e Python'
Get-Content (Join-Path $kit 'programas\npm-globais.txt') | Where-Object { $_ } | ForEach-Object {
    npm install -g $_
    if ($LASTEXITCODE -ne 0) { $falhas.Add("npm: $_") }
}
python -m pip install -r (Join-Path $kit 'programas\pip.txt')
if ($LASTEXITCODE -ne 0) { $falhas.Add('pip install') }
AtualizarPath

Write-Host '3/8 Backup do ~\.claude atual, se existir'
if (Test-Path $claude) {
    $bk = "$claude-backup-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
    robocopy $claude $bk /E /NFL /NDL /NJH /NJS /NP /XD projects file-history cache | Out-Null
    Write-Host "  backup em $bk"
}
}
New-Item -ItemType Directory -Force (Join-Path $claude 'skills') | Out-Null

Write-Host '4/8 Skills baixadas das fontes originais'
$tmp = Join-Path $env:TEMP 'setup-claude-fontes'
New-Item -ItemType Directory -Force $tmp | Out-Null
$fontes = Get-Content (Join-Path $kit 'fontes.json') -Raw | ConvertFrom-Json
foreach ($f in $fontes) {
    $dest = Join-Path $tmp (($f.repo -replace '/', '_') + '_' + $f.ref.Substring(0, 7))
    if (-not (Test-Path $dest)) {
        try {
            Invoke-WebRequest "https://codeload.github.com/$($f.repo)/tar.gz/$($f.ref)" -OutFile "$dest.tar.gz" -UseBasicParsing
            New-Item -ItemType Directory -Force $dest | Out-Null
            tar -xzf "$dest.tar.gz" -C $dest --strip-components=1 2>$null
            if ($f.montagem -eq 'remotion') { MontarRemotion $dest }
        } catch { $falhas.Add("download: $($f.repo)"); continue }
    }
    foreach ($n in $f.skills) {
        $orig = if ($f.pasta -eq '.') { $dest } elseif ($f.pasta) { Join-Path $dest "$($f.pasta)\$n" } else { Join-Path $dest $n }
        if (Test-Path $orig) { Copiar $orig (Join-Path $claude "skills\$n") } else { $falhas.Add("skill: $n") }
    }
    Write-Host "  ok $($f.repo) ($($f.skills.Count))"
}
Get-ChildItem (Join-Path $kit 'incluidas') -Directory | ForEach-Object {
    Copiar $_.FullName (Join-Path $claude "skills\$($_.Name)")
    Write-Host "  ok $($_.Name)"
}

Write-Host '5/8 Adaptadores e atalhos dos agentes'
$adapt = Join-Path $kit 'adaptadores'
Get-ChildItem $adapt -Recurse -File | ForEach-Object {
    $alvo = Join-Path $claude $_.FullName.Substring($adapt.Length + 1)
    New-Item -ItemType Directory -Force (Split-Path $alvo) | Out-Null
    [IO.File]::WriteAllText($alvo, (ComHome ([IO.File]::ReadAllText($_.FullName))), $utf8)
}
if ($SoSkills) { if ($falhas.Count) { $falhas | ForEach-Object { Write-Host "  falhou: $_" } }; exit 0 }

Write-Host '6/8 Configuração, marketplaces e plugins'
$st = Get-Content (Join-Path $kit 'claude\settings.json') -Raw | ConvertFrom-Json
$stPath = Join-Path $claude 'settings.json'
if (Test-Path $stPath) {
    # mantém o que já existir no PC novo e acrescenta o do kit
    $atual = Get-Content $stPath -Raw | ConvertFrom-Json
    foreach ($p in $st.PSObject.Properties) {
        if ($atual.PSObject.Properties[$p.Name]) { $atual.PSObject.Properties.Remove($p.Name) }
        $atual | Add-Member $p.Name $p.Value
    }
    $st = $atual
}
[IO.File]::WriteAllText($stPath, ($st | ConvertTo-Json -Depth 10), $utf8)
foreach ($m in $st.extraKnownMarketplaces.PSObject.Properties) {
    claude plugin marketplace add $m.Value.source.repo
    if ($LASTEXITCODE -ne 0) { $falhas.Add("marketplace: $($m.Value.source.repo)") }
}
$apelidos = @{ 'code-review-anthropics' = 'code-review' }
foreach ($p in $st.enabledPlugins.PSObject.Properties) {
    if (-not $p.Value) { continue }
    $nome, $mkt = $p.Name -split '@', 2
    if ($mkt -eq 'anthropic-plugin-directory') {
        $mkt = 'claude-plugins-official'
        if ($apelidos.ContainsKey($nome)) { $nome = $apelidos[$nome] }
    }
    claude plugin install "$nome@$mkt" -y
    if ($LASTEXITCODE -ne 0) { $falhas.Add("plugin: $nome@$mkt") }
}

Write-Host '7/8 Servidores MCP'
$cjPath = Join-Path $env:USERPROFILE '.claude.json'
$cj = if (Test-Path $cjPath) { Get-Content $cjPath -Raw | ConvertFrom-Json } else { [pscustomobject]@{} }
if (-not $cj.PSObject.Properties['mcpServers']) { $cj | Add-Member mcpServers ([pscustomobject]@{}) }
$novos = (ComHome (Get-Content (Join-Path $kit 'claude\mcp-servers.json') -Raw)) | ConvertFrom-Json
foreach ($m in $novos.PSObject.Properties) {
    if ($cj.mcpServers.PSObject.Properties[$m.Name]) { $cj.mcpServers.PSObject.Properties.Remove($m.Name) }
    $cj.mcpServers | Add-Member $m.Name $m.Value
    Write-Host "  ok $($m.Name)"
}
[IO.File]::WriteAllText($cjPath, ($cj | ConvertTo-Json -Depth 20), $utf8)

Write-Host '8/8 Ambiente Python do edvid'
$edvid = Join-Path $claude 'skills\edvid'
if (Test-Path $edvid) {
    Push-Location $edvid
    uv sync
    if ($LASTEXITCODE -ne 0) { $falhas.Add('edvid: uv sync') }
    Pop-Location
}

Write-Host ''
Write-Host '================ FALTA FAZER À MÃO ================'
Write-Host '1. Abrir o app Claude e entrar na sua conta. No terminal: claude -> /login'
Write-Host '2. /mcp para autorizar meta-official e firecrawl (se usar).'
Write-Host '3. MCP rea usa Ghidra em C:\tools\ghidra_12.1.4_PUBLIC: baixar em ghidra-sre.org e extrair lá.'
Write-Host '4. Pacotes pagos ficam fora deste kit público: Engenharia Civil (obra360), skills Meta do curso, Replica.'
Write-Host '   Instale-os pela sua compra/curso.'
Write-Host '5. Ativar licenças de programas pagos (Acrobat, SketchUp, Filmora) e chaves de API quando pedirem.'
if ($falhas.Count) {
    Write-Host ''
    Write-Host 'Itens que falharam (rode de novo ou instale à mão):'
    $falhas | ForEach-Object { Write-Host "  - $_" }
} else {
    Write-Host ''
    Write-Host 'Nenhuma falha automática.'
}
exit 0
