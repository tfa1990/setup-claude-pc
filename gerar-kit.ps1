# gerar-kit.ps1
# Roda no PC de origem. Atualiza este kit público a partir do que está instalado aqui.
# Não copia dados pessoais: nada de memórias, histórico, conversas, tokens ou projetos.
# Skills de terceiros NÃO são copiadas: o instalador baixa cada uma da fonte original.
# Só entram em "adaptadores/" os arquivos criados nesta máquina (atalhos de agentes,
# SKILL.md de adaptação), com o caminho do usuário trocado por {{HOME}}.

$ErrorActionPreference = 'Stop'
$kit    = Split-Path -Parent $MyInvocation.MyCommand.Path
$claude = Join-Path $env:USERPROFILE '.claude'
$homeFwd = $env:USERPROFILE.Replace('\', '/')

# fonte pública de cada skill (repositório, commit, pasta dentro do repositório)
$fontes = @(
    @{ repo = 'boraoztunc/skills'; ref = '645553ca7622570479e330cc089c65fcf34e0ba8'; pasta = ''; skills = @(
        'adversarial-review','analytics-tracking','animejs','app-store-screenshots','apple-design','beam-glow-states',
        'beautiful-shadows','better-accessibility','better-colors','better-interface','better-layout','better-typography',
        'better-ui','better-writing','competitor-alternatives','conductor-rewrite-performance','container-lines',
        'content-strategy','contribute-catalog','copy-editing','copywriting','corner-diagonals','css-animations',
        'css-border-gradient','documentary-brutalist-agency','editorial-portfolio-chapters','emil-design-eng',
        'framed-grid-layout','frontend-design','glass-dark-ui','gsap','hyperframes-cli','hyperframes-media',
        'hyperframes-registry','hyperframes','impeccable','interface-review','landing-page','linear-local-first-architecture',
        'liquid-metal-border','lottie','mesh-gradient-dark-blue-clean','minimal-zine-poster','ogilvy',
        'operational-enterprise-ai','page-cro','pricing-page','product-proof-saas','programmatic-seo','progressive-blur',
        'remotion-to-hyperframes','reveal-hover-effect','schema-markup','seo-audit','service-booking-flow',
        'shaders-cursor-ripples','skeuomorphic-ui','staggered-word-reveal','stop-slop','tailwind-v4','tailwind',
        'thinking-orbs','three','typegpu','vercel-react-best-practices','visual-style-presets','waapi',
        'web-design-guidelines','webgl-laser','website-to-hyperframes') }
    @{ repo = 'ComposioHQ/awesome-claude-skills'; ref = 'be2a406907dbc61b73e6827ded415c96139d13a2'; pasta = ''; skills = @(
        'artifacts-builder','brand-guidelines','canvas-design','changelog-generator','competitive-ads-extractor',
        'connect-apps','connect','content-research-writer','developer-growth-analysis','domain-name-brainstormer',
        'file-organizer','image-enhancer','internal-comms','invoice-organizer','langsmith-fetch',
        'lead-research-assistant','mcp-builder','meeting-insights-analyzer','raffle-winner-picker','skill-creator',
        'skill-share','slack-gif-creator','tailored-resume-generator','theme-factory','twitter-algorithm-optimizer',
        'video-downloader','webapp-testing') }
    @{ repo = 'firecrawl/cli'; ref = '2de80d5c7a89cabfbf6aa4d068418eb569fbc273'; pasta = 'skills'; skills = @(
        'firecrawl-agent','firecrawl-alexandria','firecrawl-crawl','firecrawl-developer-index','firecrawl-download',
        'firecrawl-interact','firecrawl-map','firecrawl-monitor','firecrawl-parse','firecrawl-research-index',
        'firecrawl-scrape','firecrawl-search','firecrawl') }
    @{ repo = 'replicate/skills'; ref = '2f36e415965ae63baa1c9f6635888092bcd771d3'; pasta = 'skills'; skills = @(
        'compare-models','find-models','run-models','prompt-images','prompt-videos') }
    @{ repo = 'ohmyjahh/xquads-squads'; ref = 'cd5e7985d7886e617e6c84cb4156d35e1b5c69df'; pasta = ''; skills = @(
        'advisory-board','brand-squad','c-level-squad','claude-code-mastery','copy-master','copy-squad',
        'cybersecurity','data-squad','design-squad','hormozi-squad','marketing-squad','movement','storytelling',
        'traffic-masters','xquads') }
    @{ repo = 'ohmyjahh/builder-squad'; ref = '5cbb2d3c5ced484b5df895f0f19a39c14b86e46f'; pasta = '.'; skills = @('builder-squad') }
    @{ repo = 'morluto/rea'; ref = '0ffed7a48c43bcf1aef760d307be89f0a055ee4a'; pasta = '.agents/skills'; skills = @('reverse-engineer-anything') }
    # montagem 'remotion': raiz do repositório + skills/remotion-best-practices + cada skills/remotion-* ao lado
    @{ repo = 'remotion-dev/skills'; ref = '30d4553ecd46fbc5212fd0ff006ae43af522158b'; pasta = '.'; montagem = 'remotion'; skills = @('remotion-best-practices') }
)
# licença MIT e sem fonte pública hoje: vai copiada em incluidas/ junto com o LICENSE
$incluidas = @('edvid')
# pagas/proprietárias ou pessoais: nunca vão para o kit público
$privadas = '^(agente-trafego-pago|meta-.*|replica-.*|google-maps-scraper|synced)$'

function TextoNormal([string]$p) { ([IO.File]::ReadAllText($p)).Replace("`r`n", "`n") }
function EhTexto([string]$p) { $p -match '\.(md|txt|ya?ml|json|js|mjs|ts|tsx|py|sh|ps1|toml|csv|html|css)$' }
function SemHome([string]$t) {
    $t.Replace($env:USERPROFILE, '{{HOME}}').Replace($homeFwd, '{{HOME}}').Replace($env:USERPROFILE.Replace('\', '\\'), '{{HOME}}')
}

function MontarRemotion([string]$raiz) {
    $sk = Join-Path $raiz 'skills'
    robocopy (Join-Path $sk 'remotion-best-practices') $raiz /E /NFL /NDL /NJH /NJS /NP | Out-Null
    Get-ChildItem $sk -Directory -Filter 'remotion-*' | Where-Object Name -ne 'remotion-best-practices' | ForEach-Object {
        robocopy $_.FullName (Join-Path $raiz $_.Name) /E /NFL /NDL /NJH /NJS /NP | Out-Null
    }
}

$adapt = Join-Path $kit 'adaptadores'
if (Test-Path $adapt) { robocopy (New-Item -ItemType Directory -Force "$env:TEMP\vazio-kit").FullName $adapt /MIR /NFL /NDL /NJH /NJS /NP | Out-Null }
New-Item -ItemType Directory -Force $adapt | Out-Null

Write-Host '1/4 Comparando skills locais com as fontes públicas'
$tmp = Join-Path $env:TEMP 'setup-claude-fontes'
New-Item -ItemType Directory -Force $tmp | Out-Null
$cobertas = @()
foreach ($f in $fontes) {
    $dest = Join-Path $tmp (($f.repo -replace '/', '_') + '_' + $f.ref.Substring(0, 7))
    if (-not (Test-Path $dest)) {
        $tgz = "$dest.tar.gz"
        Invoke-WebRequest "https://codeload.github.com/$($f.repo)/tar.gz/$($f.ref)" -OutFile $tgz -UseBasicParsing
        New-Item -ItemType Directory -Force $dest | Out-Null
        tar -xzf $tgz -C $dest --strip-components=1 2>$null
        if ($f.montagem -eq 'remotion') { MontarRemotion $dest }
    }
    foreach ($n in $f.skills) {
        $cobertas += $n
        $local = Join-Path $claude "skills\$n"
        $orig  = if ($f.pasta -eq '.') { $dest } elseif ($f.pasta) { Join-Path $dest "$($f.pasta)\$n" } else { Join-Path $dest $n }
        # versões locais antigas dessas fontes: usa a oficial, sem adaptador
        if (-not (Test-Path $local) -or $f.repo -in @('remotion-dev/skills', 'morluto/rea')) { continue }
        Get-ChildItem $local -Recurse -File | ForEach-Object {
            $rel = $_.FullName.Substring($local.Length + 1)
            $o = Join-Path $orig $rel
            $igual = (Test-Path $o) -and $(if (EhTexto $_.FullName) { (TextoNormal $_.FullName) -eq (TextoNormal $o) } else { (Get-FileHash $_.FullName).Hash -eq (Get-FileHash $o).Hash })
            if (-not $igual -and (EhTexto $_.FullName)) {
                $alvo = Join-Path $adapt "skills\$n\$rel"
                New-Item -ItemType Directory -Force (Split-Path $alvo) | Out-Null
                [IO.File]::WriteAllText($alvo, (SemHome (TextoNormal $_.FullName)), (New-Object Text.UTF8Encoding $false))
                Write-Host "  adaptador: skills\$n\$rel"
            }
        }
    }
}
$inc = Join-Path $kit 'incluidas'
foreach ($n in $incluidas) {
    robocopy (Join-Path $claude "skills\$n") (Join-Path $inc $n) /MIR /NFL /NDL /NJH /NJS /NP /XD .venv __pycache__ node_modules "$n.egg-info" | Out-Null
    Write-Host "  incluída: $n"
}
$fora = Get-ChildItem (Join-Path $claude 'skills') -Directory | Where-Object {
    $_.Name -notin $cobertas -and $_.Name -notin $incluidas -and $_.Name -notmatch $privadas
}
if ($fora) { Write-Host "  ATENÇÃO, skills sem fonte conhecida (não entram): $($fora.Name -join ', ')" }

Write-Host '2/4 Atalhos dos agentes (commands)'
Get-ChildItem (Join-Path $claude 'commands') -Recurse -File -Filter *.md | ForEach-Object {
    $rel = $_.FullName.Substring((Join-Path $claude 'commands').Length + 1)
    $alvo = Join-Path $adapt "commands\$rel"
    New-Item -ItemType Directory -Force (Split-Path $alvo) | Out-Null
    [IO.File]::WriteAllText($alvo, (SemHome (TextoNormal $_.FullName)), (New-Object Text.UTF8Encoding $false))
}

Write-Host '3/4 Configuração do Claude, plugins e MCP (sem pacotes pagos)'
$cfgDir = Join-Path $kit 'claude'
New-Item -ItemType Directory -Force $cfgDir | Out-Null
$st = Get-Content (Join-Path $claude 'settings.json') -Raw | ConvertFrom-Json
foreach ($m in @($st.extraKnownMarketplaces.PSObject.Properties)) {
    if ($m.Value.source.source -ne 'github') { $st.extraKnownMarketplaces.PSObject.Properties.Remove($m.Name) }
}
foreach ($p in @($st.enabledPlugins.PSObject.Properties)) {
    $mkt = ($p.Name -split '@', 2)[1]
    $publico = $mkt -in @('anthropic-plugin-directory', 'claude-plugins-official') -or $st.extraKnownMarketplaces.PSObject.Properties[$mkt]
    if (-not $publico) { $st.enabledPlugins.PSObject.Properties.Remove($p.Name) }
}
[IO.File]::WriteAllText((Join-Path $cfgDir 'settings.json'), (SemHome ($st | ConvertTo-Json -Depth 10)), (New-Object Text.UTF8Encoding $false))
$cj = Get-Content (Join-Path $env:USERPROFILE '.claude.json') -Raw | ConvertFrom-Json
[IO.File]::WriteAllText((Join-Path $cfgDir 'mcp-servers.json'), (SemHome ($cj.mcpServers | ConvertTo-Json -Depth 10)), (New-Object Text.UTF8Encoding $false))

Write-Host '4/4 Programas (winget, npm, pip)'
$prog = Join-Path $kit 'programas'
New-Item -ItemType Directory -Force $prog | Out-Null
$wgTmp = Join-Path $env:TEMP 'winget-export.json'
winget export -o $wgTmp --accept-source-agreements | Out-Null
$foraWg = '^(Microsoft\.(VCRedist|VCLibs|UI\.Xaml|WindowsAppRuntime|DotNet|WindowsSDK|AppInstaller|msodbcsql|OneDrive|Edge|Teams|Outlook|365Copilot|WSL)|EPSON\.|TechPowerUp\.|Wondershare\.UniConverter\.1[56]$)'
$wg = Get-Content $wgTmp -Raw | ConvertFrom-Json
foreach ($s in $wg.Sources) { $s.Packages = @($s.Packages | Where-Object { $_.PackageIdentifier -notmatch $foraWg }) }
$wg.PSObject.Properties.Remove('CreationDate')
[IO.File]::WriteAllText((Join-Path $prog 'winget.json'), ($wg | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding $false))
$npmJson = npm ls -g --depth=0 --json | ConvertFrom-Json
$npm = $npmJson.dependencies.PSObject.Properties.Name | Where-Object { $_ -notin @('npm', 'corepack') }
[IO.File]::WriteAllText((Join-Path $prog 'npm-globais.txt'), (($npm -join "`n") + "`n"), (New-Object Text.UTF8Encoding $false))
$pip = python -m pip freeze | Where-Object { $_ -notmatch '^(pip|setuptools)==' }
[IO.File]::WriteAllText((Join-Path $prog 'pip.txt'), (($pip -join "`n") + "`n"), (New-Object Text.UTF8Encoding $false))
$fontes | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $kit 'fontes.json') -Encoding utf8

# última trava: nenhum arquivo do kit pode conter o nome de usuário desta máquina
$vaza = Get-ChildItem $kit -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.Name -ne 'gerar-kit.ps1' } |
    Select-String -Pattern ('(?<![\w])' + [regex]::Escape($env:USERNAME) + '(?![\w])') -List
if ($vaza) { $vaza | ForEach-Object { Write-Host "  VAZAMENTO: $($_.Path)" }; throw 'Kit contém o nome de usuário. Nada foi enviado.' }

Write-Host ''
Write-Host 'Kit gerado. Revise o git diff antes de enviar.'
exit 0
