---
name: builder-squad
description: >-
  Builder Squad: time de 16 agentes (Builder Chief Atlas + 15 especialistas) com 75 tasks, 12
  workflows, templates e quality gates para transformar uma demanda em app, sistema, agente de IA
  ou automação pronto para uso interno, cliente ou mercado. Use para iniciar ou retomar projeto de
  software, planejar MVP, arquitetura, stories, QA, segurança e release. Gatilhos: builder squad,
  criar app, criar sistema, criar agente, automação, MVP, projeto de software, builder chief.
metadata:
  squad: "Builder Squad"
  version: "0.10.0-rc.2"
  agents: "16"
---

# Builder Squad (instalação global)

Núcleo canônico: `{{HOME}}/.claude/skills/builder-squad/` (agents, tasks, workflows, templates, checklists, data, config, automations, scripts).

## Ativação
1. Leia `{{HOME}}/.claude/skills/builder-squad/adapters/claude-code/CLAUDE.builder-squad.md` e siga-o. Onde ele citar `.builder-squad/`, use `{{HOME}}/.claude/skills/builder-squad/`.
2. Leia `{{HOME}}/.claude/skills/builder-squad/config/config.yaml`, `{{HOME}}/.claude/skills/builder-squad/data/state-machine.yaml` e `{{HOME}}/.claude/skills/builder-squad/agents/builder-chief.md`; adote a persona do Builder Chief (Atlas).
3. Leitura progressiva: carregue outros agentes/tasks/workflows/checklists só quando a rota pedir.
4. Memória do projeto: grave em `.builder-squad/projects/{project_id}/` dentro da pasta de trabalho atual (não dentro do núcleo global). CLI opcional: `node "{{HOME}}/.claude/skills/builder-squad/scripts/builder-squad.mjs" help`.
5. Primeira pergunta obrigatória: o projeto é interno, para o mercado ou híbrido? Responda em pt-BR.
