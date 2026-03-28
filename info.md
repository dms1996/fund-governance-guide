# Fund Governance Simulation - Guia Completo

> Este documento explica todos os ficheiros do projeto, o seu propósito, quando os usar, e simula o fluxo de trabalho real do dia a dia numa equipa de Fund Governance.

---

## Indice

1. [Visao Geral do Projeto](#visao-geral-do-projeto)
2. [Mapa de Ficheiros](#mapa-de-ficheiros)
3. [Explicacao Detalhada por Pasta](#explicacao-detalhada-por-pasta)
4. [Simulacao do Dia a Dia](#simulacao-do-dia-a-dia)
5. [Fluxo Semanal e Mensal](#fluxo-semanal-e-mensal)
6. [Fluxo Trimestral e Anual](#fluxo-trimestral-e-anual)
7. [Cenarios Praticos](#cenarios-praticos)
8. [Glossario](#glossario)

---

## Visao Geral do Projeto

Este projeto simula as operacoes de governance de 6 fundos de investimento:

| Fundo | Tipo | Domicilio | AUM (EUR) |
|-------|------|-----------|-----------|
| Global Equity Fund | UCITS | Irlanda | 487.3M |
| European Bond Fund | UCITS | Irlanda | 312.8M |
| Multi-Asset Growth Fund | UCITS | Luxemburgo | 623.4M |
| Emerging Markets Fund | UCITS | Irlanda | 198.5M |
| Real Estate Opportunities | AIFMD | Luxemburgo | 145.6M |
| Private Credit Fund | AIFMD | Luxemburgo | 89.2M |

O projeto cobre **todo o ciclo de vida** de governance: desde o setup inicial de um fundo, passando pela reconciliacao diaria de NAV, monitorizacao de compliance, calculo de fees, ate ao reporting para investidores, reguladores e board.

---

## Mapa de Ficheiros

```
Fund-Governance-Simulation/
│
├── README.md                        # Visao geral tecnica do projeto
├── info.md                          # ESTE FICHEIRO - guia completo
│
├── 01-Fund-Setup/                   # Registo e estrutura dos fundos
│   ├── fund_register.csv            # Base de dados mestre dos fundos
│   ├── fund_setup_checklist.md      # Checklist para lancar um fundo novo
│   └── fund_structure_overview.md   # Estrutura juridica e governance
│
├── 02-NAV-Reconciliation/           # Reconciliacao diaria do NAV
│   ├── nav_daily_report.csv         # Valores NAV diarios de todos os fundos
│   ├── nav_breaks_log.csv           # Registo de discrepancias encontradas
│   └── nav_reconciliation.sql       # Queries SQL para validar NAVs
│
├── 03-Compliance-Monitoring/        # Monitorizacao de conformidade
│   ├── compliance_checklist.csv     # Verificacoes de limites de investimento
│   ├── compliance_policy.md         # Politica de compliance completa
│   ├── aml_kyc_tracker.csv          # Estado do KYC/AML de cada investidor
│   └── regulatory_breaches_log.csv  # Registo de violacoes regulatorias
│
├── 04-Fee-Calculations/             # Calculo e validacao de comissoes
│   ├── management_fees.csv          # Comissoes de gestao acumuladas
│   ├── performance_fees.csv         # Comissoes de performance (HWM)
│   └── fee_validation.sql           # Queries SQL para validar fees
│
├── 05-Board-Reporting/              # Reporting para o Conselho de Administracao
│   ├── board_pack_q4_2025.md        # Exemplo de pack para reuniao do board
│   ├── fund_performance_summary.csv # Resumo de performance por fundo
│   └── risk_dashboard_data.csv      # Metricas de risco (VaR, volatilidade)
│
├── 06-Investor-Reporting/           # Comunicacao com investidores
│   ├── investor_register.csv        # Registo de todos os investidores
│   ├── investor_report_template.md  # Template para relatorio mensal
│   └── monthly_factsheet_data.csv   # Dados para factsheet mensal
│
├── 07-Regulatory-Reporting/         # Reporting regulatorio
│   ├── regulatory_calendar.csv      # Calendario de obrigacoes regulatorias
│   ├── ucits_reporting_data.csv     # Dados para reportes UCITS
│   └── aifmd_annex_iv_data.csv      # Dados para Annex IV (AIFMD)
│
├── 08-Business-Analysis/            # Documentacao de projeto BA
│   ├── BRD_nav_automation.md        # Business Requirements Document
│   ├── user_stories.md              # User stories para desenvolvimento
│   ├── gap_analysis.csv             # Analise de gaps operacionais
│   └── data_dictionary.csv          # Dicionario de dados completo
│
├── 09-SQL-Scripts/                  # Scripts SQL para analise de dados
│   ├── nav_validation.sql           # Validacao de dados NAV
│   ├── fee_reconciliation.sql       # Reconciliacao de comissoes
│   ├── investor_data_extract.sql    # Extracao de dados de investidores
│   └── aum_tracking.sql             # Tracking de AUM ao longo do tempo
│
└── 10-Python-Automation/            # Scripts de automacao
    ├── nav_break_analysis.py        # Detecao automatica de NAV breaks
    ├── fee_calculator.py            # Calculadora de management/performance fees
    └── report_generator.py          # Gerador automatico de board packs
```

---

## Explicacao Detalhada por Pasta

### 01 - Fund Setup (Registo e Estrutura dos Fundos)

**O que e?** A base de tudo. Contem a informacao mestre de cada fundo e os processos para lancar novos fundos.

| Ficheiro | O que contem | Quando usar |
|----------|-------------|-------------|
| `fund_register.csv` | ID, nome, ISIN, tipo (UCITS/AIFMD), domicilio, AUM, administrador de cada fundo | Sempre que precisas de consultar dados basicos de um fundo. E a "ficha de identidade" de cada fundo. |
| `fund_setup_checklist.md` | Checklist de 4 fases para lancar um fundo (Pre-Launch, Setup, Go-Live, Post-Launch) | Quando a empresa decide lancar um fundo novo. Segues esta checklist passo a passo. |
| `fund_structure_overview.md` | Estrutura juridica (ICAV, SICAV), umbrellas, share classes, board members | Para entender como os fundos estao organizados juridicamente e quem e responsavel por que. |

**Conceito-chave:** Cada fundo pertence a um "umbrella" (veiculo juridico). Por exemplo, o Global Equity, European Bond e Emerging Markets estao todos debaixo do "CMC UCITS Platform ICAV" na Irlanda. Isto e como uma empresa-mae com varias sub-divisoes.

---

### 02 - NAV Reconciliation (Reconciliacao Diaria do NAV)

**O que e?** O NAV (Net Asset Value) e o valor liquido de cada fundo por unidade de participacao. Todos os dias, o administrador do fundo calcula o NAV e a equipa de governance verifica se esta correto.

| Ficheiro | O que contem | Quando usar |
|----------|-------------|-------------|
| `nav_daily_report.csv` | NAV por share, shares outstanding, NAV total, retorno diario, por fundo e por dia | Todos os dias de manha, quando recebes o NAV do administrador. Comparas com os teus calculos internos. |
| `nav_breaks_log.csv` | Lista de discrepancias (breaks): tipo, severidade, causa, estado, resolucao | Quando encontras uma diferenca entre o teu NAV e o do administrador. Registas aqui e acompanhas ate resolver. |
| `nav_reconciliation.sql` | 5 queries SQL para comparar, validar e analisar breaks | Para correr as validacoes automaticas contra a base de dados. |

**Conceito-chave:** Um "NAV break" acontece quando o valor que tu calculas internamente difere do valor calculado pelo administrador do fundo. Se a diferenca for superior a 0.01% (tolerancia), tens de investigar. As causas comuns sao: erro de pricing, taxa de cambio errada, acao corporativa nao processada, ou erro de accrual.

---

### 03 - Compliance Monitoring (Monitorizacao de Conformidade)

**O que e?** Verifica que cada fundo cumpre as regras regulatorias e internas. Fundos UCITS e AIFMD tem regras diferentes sobre quanto podem investir em que.

| Ficheiro | O que contem | Quando usar |
|----------|-------------|-------------|
| `compliance_checklist.csv` | 27 verificacoes: limites UCITS (regra 5/10/40), AIFMD (leverage), estado de cada verificacao | Todos os dias, apos a reconciliacao do NAV. Verificas se algum limite foi ultrapassado. |
| `compliance_policy.md` | Politica completa: framework, procedimentos diarios, limites hard/soft, escalation | Documento de referencia. Consultas quando tens duvida sobre que regra se aplica ou qual o procedimento de escalation. |
| `aml_kyc_tracker.csv` | Estado do KYC de cada investidor: documentos, nivel de risco, PEP, sancoes | Quando um investidor novo quer subscrever, ou quando o KYC de um investidor existente precisa de renovacao. |
| `regulatory_breaches_log.csv` | Historico de violacoes: data, tipo, severidade, causa, resolucao, licoes aprendidas | Quando ocorre uma violacao. Registas aqui e acompanhas ate resolver. Tambem usado para reportar ao board. |

**Conceito-chave:** A regra 5/10/40 em UCITS significa: maximo 5% num unico emitente, excepcoes ate 10%, e o total de posicoes >5% nao pode exceder 40% do fundo. Se o mercado sobe e uma posicao ultrapassa o limite, tens um "passive breach" que precisa de ser corrigido.

---

### 04 - Fee Calculations (Calculo de Comissoes)

**O que e?** Os fundos cobram comissoes aos investidores. As duas principais sao management fees (percentagem fixa sobre o AUM) e performance fees (percentagem sobre o retorno acima de um benchmark).

| Ficheiro | O que contem | Quando usar |
|----------|-------------|-------------|
| `management_fees.csv` | Accruals diarios de management fees por fundo e share class | Diariamente para verificar se o accrual esta correto. Mensalmente para reconciliar com pagamentos. |
| `performance_fees.csv` | Performance fees: high-water mark, hurdle rate, retorno vs benchmark, estado | Diariamente para tracking. Em datas de cristalizacao (trimestral/anual) para confirmar os valores finais. |
| `fee_validation.sql` | 7 queries SQL para validar fees contra o prospeto, reconciliar accruals vs pagamentos | Para auditar se as fees estao a ser calculadas corretamente. |

**Conceito-chave:** O High-Water Mark (HWM) garante que o gestor so cobra performance fee sobre novos maximos. Se o fundo cai de 110 para 100 e depois sobe para 105, nao ha performance fee porque ainda esta abaixo do maximo anterior (110).

---

### 05 - Board Reporting (Reporting para o Board)

**O que e?** Trimestralmente, a equipa prepara um "board pack" - um documento completo sobre o estado de todos os fundos para apresentar ao Conselho de Administracao.

| Ficheiro | O que contem | Quando usar |
|----------|-------------|-------------|
| `board_pack_q4_2025.md` | Exemplo completo: ata de reuniao, AUM, performance, risco, compliance, fees, regulatorio | Trimestralmente. Este e o produto final que vai para o board. |
| `fund_performance_summary.csv` | NAV, retornos (MTD, QTD, YTD, 1Y, 3Y), Sharpe ratio, max drawdown por fundo | Para preparar o board pack. Os dados de performance vem daqui. |
| `risk_dashboard_data.csv` | VaR, tracking error, volatilidade, leverage, concentracao por fundo e por mes | Para a seccao de risco do board pack. |

**Conceito-chave:** O board pack e o documento mais importante do trimestre. Resume TUDO o que aconteceu. Os board members (diretores independentes) usam-no para tomar decisoes sobre os fundos.

---

### 06 - Investor Reporting (Comunicacao com Investidores)

**O que e?** Mensalmente, os investidores recebem relatorios e factsheets sobre os fundos onde investiram.

| Ficheiro | O que contem | Quando usar |
|----------|-------------|-------------|
| `investor_register.csv` | 25 investidores: nome, tipo, pais, fundo, share class, AUM, relationship manager | Para consultar quem sao os investidores e em que fundos estao. |
| `investor_report_template.md` | Template com placeholders para gerar o relatorio mensal | Mensalmente, preenchido com os dados reais do mes. |
| `monthly_factsheet_data.csv` | NAV, AUM, retornos, volatilidade, top holdings por fundo | Os dados que alimentam a factsheet mensal. |

**Conceito-chave:** Investidores institucionais (fundos de pensao, seguradoras) recebem relatorios detalhados. Investidores retail recebem factsheets mais simples. Ambos sao obrigatorios por regulacao.

---

### 07 - Regulatory Reporting (Reporting Regulatorio)

**O que e?** Os fundos tem obrigacoes de reportar informacao aos reguladores (CBI na Irlanda, CSSF no Luxemburgo, ESMA a nivel europeu).

| Ficheiro | O que contem | Quando usar |
|----------|-------------|-------------|
| `regulatory_calendar.csv` | 21 obrigacoes: tipo, fundo, frequencia, data limite, responsavel, estado | Consultado todas as semanas para verificar que prazos se aproximam. |
| `ucits_reporting_data.csv` | Dados para reportes UCITS: NAV, investidores, subscricoes, limites | Trimestralmente, quando preparas o CBI Online Return. |
| `aifmd_annex_iv_data.csv` | Dados para Annex IV AIFMD: AUM, leverage, liquidez, emprestimos | Trimestralmente, para os fundos alternativos (Real Estate e Private Credit). |

**Conceito-chave:** Falhar um prazo regulatorio e grave - pode resultar em multas e danos reputacionais. O calendario regulatorio e revisto semanalmente para garantir que nada e esquecido.

---

### 08 - Business Analysis (Documentacao de Projeto)

**O que e?** Documentacao de um projeto real de automacao - transformar o processo manual de reconciliacao de NAV num sistema automatizado.

| Ficheiro | O que contem | Quando usar |
|----------|-------------|-------------|
| `BRD_nav_automation.md` | Business Requirements Document: problema, objetivos, requisitos, timeline | No inicio do projeto. Define O QUE precisa de ser construido e PORQUE. |
| `user_stories.md` | 12 user stories com criterios de aceitacao e story points | Para a equipa de desenvolvimento saber exatamente o que implementar. |
| `gap_analysis.csv` | 17 gaps identificados entre o estado atual e o desejado | Para priorizar que problemas resolver primeiro. |
| `data_dictionary.csv` | 45 campos definidos: nome, tipo, descricao, regras de negocio, exemplos | Para qualquer pessoa que precise de entender a estrutura de dados. |

**Conceito-chave:** Esta pasta mostra o papel de Business Analyst - traduzir necessidades de negocio em requisitos tecnicos. O BRD e o documento central que alinha stakeholders.

---

### 09 - SQL Scripts (Scripts de Analise)

**O que e?** Queries SQL prontas a usar para analisar dados de fundos. Simulam o que correrias contra uma base de dados real.

| Ficheiro | O que faz | Quando usar |
|----------|----------|-------------|
| `nav_validation.sql` | 7 validacoes: NAVs em falta, duplicados, retornos anormais, precos stale | Diariamente como parte da validacao do NAV. |
| `fee_reconciliation.sql` | 6 queries: accruals vs esperado, cristalizacao, rate vs prospeto | Mensalmente para reconciliar fees. Trimestralmente para o board. |
| `investor_data_extract.sql` | 7 queries: registo completo, atividade, concentracao, distribuicao geografica | Para preparar investor reports ou responder a pedidos ad-hoc. |
| `aum_tracking.sql` | 6 queries: AUM diario, atribuicao (mercado vs fluxos), crescimento YoY | Para tracking de AUM e preparacao de board packs. |

---

### 10 - Python Automation (Automacao)

**O que e?** Scripts Python que automatizam tarefas manuais repetitivas.

| Ficheiro | O que faz | Quando usar |
|----------|----------|-------------|
| `nav_break_analysis.py` | Carrega dados NAV, deteta breaks automaticamente, classifica por severidade | Diariamente para substituir a verificacao manual de NAV breaks. |
| `fee_calculator.py` | Calcula management fees e performance fees com logica de HWM | Diariamente para accruals. Em datas de cristalizacao para validacao final. |
| `report_generator.py` | Gera dados para board packs: performance, risco, AUM | Trimestralmente para automatizar a preparacao do board pack. |

---

## Simulacao do Dia a Dia

### Um Dia Tipico (Segunda a Sexta)

---

#### 08:30 - Chegada e Verificacao de Emails

Recebes emails do administrador do fundo (Fund Administrator) com os ficheiros NAV do dia anterior.

**Acao:** Abres `02-NAV-Reconciliation/nav_daily_report.csv` e adicionas os novos valores recebidos.

```
Exemplo de email:
"Subject: Daily NAV Report - CMC UCITS Platform - 27 March 2026
Attached: NAV_20260327.xlsx
Global Equity Fund - Institutional: EUR 142.87 per share
European Bond Fund - Institutional: EUR 103.21 per share
..."
```

---

#### 09:00 - Reconciliacao do NAV

Comparas o NAV recebido do administrador com o teu calculo interno (feito no sistema Fund Accounting System ou similar).

**Acao 1:** Corres as queries de `09-SQL-Scripts/nav_validation.sql` contra a base de dados para detetar problemas automaticos (NAVs em falta, duplicados, retornos anormais).

**Acao 2:** Corres `10-Python-Automation/nav_break_analysis.py` para comparar automaticamente os valores e detetar breaks.

**Acao 3 (se houver break):** Abres `02-NAV-Reconciliation/nav_breaks_log.csv` e registas:

```csv
BRK-011,FND-001,2026-03-27,Pricing Error,High,EUR 0.15 per share,Open,Investigating,...
```

**Acao 4 (se houver break):** Envias email ao administrador a pedir esclarecimento:

```
"Subject: NAV Break - Global Equity Fund - 27/03/2026
Identificamos uma diferenca de EUR 0.15 por share no NAV do Global Equity Fund.
O nosso calculo interno: EUR 142.72. O vosso valor: EUR 142.87.
Podem por favor confirmar o pricing do Tech Corp B (ISIN XX0000000000)?
..."
```

---

#### 10:00 - Verificacao de Compliance

Apos confirmar os NAVs, verificas se algum limite regulatorio foi ultrapassado.

**Acao 1:** Consultas `03-Compliance-Monitoring/compliance_checklist.csv` e atualizas o estado de cada verificacao.

**Acao 2 (se houver breach):** Por exemplo, descobres que a posicao da Issuer Y no Emerging Markets Fund subiu para 10.4% (limite UCITS e 10%).

**Acao 3:** Registas em `03-Compliance-Monitoring/regulatory_breaches_log.csv`:

```csv
BRC-010,FND-004,2026-03-27,Passive UCITS Breach,Medium,Market movement pushed Issuer Y to 10.4%,Open,...
```

**Acao 4:** Envias email ao gestor do fundo:

```
"Subject: UCITS Breach Alert - Emerging Markets Fund - Issuer Y Position
A posicao da Issuer Y excede o limite de 10% (atualmente 10.4%).
Como se trata de um passive breach (causado por movimento de mercado),
temos 30 dias para corrigir. Recomendamos reduzir a posicao na proxima
oportunidade de trading.
Aprovacao necessaria: Compliance Officer."
```

**Acao 5:** Consultas `03-Compliance-Monitoring/compliance_policy.md` para confirmar o procedimento correto de escalation.

---

#### 11:00 - Verificacao de Fees

Verificas se as comissoes estao a ser acumuladas corretamente.

**Acao 1:** Corres `10-Python-Automation/fee_calculator.py` para calcular os accruals do dia.

**Acao 2:** Comparas com `04-Fee-Calculations/management_fees.csv` e atualizas os valores.

**Acao 3:** Se e uma data de cristalizacao de performance fees, verificas `04-Fee-Calculations/performance_fees.csv` e corres as queries de `04-Fee-Calculations/fee_validation.sql` para validar os valores contra o prospeto.

---

#### 11:30 - Verificacao de KYC/AML

Verificas se ha investidores com KYC a expirar ou novos pedidos de subscricao.

**Acao:** Consultas `03-Compliance-Monitoring/aml_kyc_tracker.csv`.

```
Exemplo: Recebes email do relationship manager:
"Subject: New Subscription Request - Dubai Sovereign Wealth Fund
O Gulf Capital Authority quer subscrever EUR 15M no Real Estate Fund.
Podem confirmar se o KYC esta completo?"

Verificas o tracker: INV-016, KYC Status = Complete, AML Risk = Medium.
Respondes: "KYC completo e valido ate 2026-11-15. Podem prosseguir com a subscricao."
```

---

#### 14:00 - Trabalho Ad-Hoc / Projetos

Trabalhas em projetos como a automacao do NAV.

**Acao:** Consultas `08-Business-Analysis/BRD_nav_automation.md` para verificar requisitos, atualizas o progresso no `08-Business-Analysis/gap_analysis.csv`, e trabalhas nas user stories de `08-Business-Analysis/user_stories.md`.

---

#### 16:00 - Verificacao do Calendario Regulatorio

**Acao:** Consultas `07-Regulatory-Reporting/regulatory_calendar.csv` para ver se ha prazos proximos.

```
Exemplo: Notas que o "UCITS CBI Online Return Q1 2026" vence a 2026-04-15.
Comecas a preparar os dados em 07-Regulatory-Reporting/ucits_reporting_data.csv.
```

---

#### 17:00 - Resolucao de Breaks Pendentes

Recebes resposta do administrador sobre o NAV break da manha.

**Acao:** Atualizas `02-NAV-Reconciliation/nav_breaks_log.csv`:

```csv
BRK-011,FND-001,2026-03-27,Pricing Error,High,EUR 0.15,Resolved,Admin confirmed pricing error on Tech Corp B - NAV restated,...
```

---

### Resumo Visual do Dia

```
08:30  Email com NAVs ──────> nav_daily_report.csv (atualizar)
  │
09:00  Reconciliacao ───────> nav_validation.sql + nav_break_analysis.py
  │                              │
  │                    Break? ──> nav_breaks_log.csv (registar)
  │                              │
  │                              > Email ao administrador
  │
10:00  Compliance ──────────> compliance_checklist.csv (verificar)
  │                              │
  │                  Breach? ──> regulatory_breaches_log.csv (registar)
  │                              │
  │                              > compliance_policy.md (consultar procedimento)
  │                              │
  │                              > Email ao gestor + Compliance Officer
  │
11:00  Fees ────────────────> fee_calculator.py (calcular)
  │                              │
  │                              > management_fees.csv (atualizar)
  │                              > performance_fees.csv (verificar HWM)
  │
11:30  KYC/AML ────────────> aml_kyc_tracker.csv (verificar)
  │
14:00  Projetos ────────────> BRD, user_stories, gap_analysis
  │
16:00  Calendario ──────────> regulatory_calendar.csv (verificar prazos)
  │
17:00  Fecho ───────────────> Atualizar breaks, fechar items resolvidos
```

---

## Fluxo Semanal e Mensal

### Todas as Sextas-feiras

1. **Revisao semanal de compliance:** Revesao de todos os items em `compliance_checklist.csv` com estado "Warning" ou "Fail"
2. **Revisao do calendario regulatorio:** Verificar `regulatory_calendar.csv` para a semana seguinte
3. **Status update de breaks:** Revisar todos os breaks "Open" em `nav_breaks_log.csv` e escalar se necessario

### Fim de Cada Mes (Ultimos 3 dias uteis)

1. **Preparar factsheets:** Usar dados de `monthly_factsheet_data.csv` + template de `investor_report_template.md` para gerar relatorios de investidores
2. **Reconciliacao de fees mensal:** Correr `fee_reconciliation.sql` para verificar accruals vs pagamentos em `management_fees.csv`
3. **Atualizar AUM:** Correr `aum_tracking.sql` para ter os valores finais do mes
4. **Extrair dados de investidores:** Correr `investor_data_extract.sql` para atualizar o registo em `investor_register.csv`
5. **Enviar investor reports:** Preencher `investor_report_template.md` com dados reais e enviar a cada investidor

```
Fim do Mes:
  monthly_factsheet_data.csv ─────> investor_report_template.md ─────> Email a investidores
  management_fees.csv ────────────> fee_reconciliation.sql ──────────> Reconciliacao
  investor_register.csv ──────────> investor_data_extract.sql ───────> Atualizacoes
```

---

## Fluxo Trimestral e Anual

### Fim de Cada Trimestre

1. **Preparar Board Pack:**
   - Reunir dados de `fund_performance_summary.csv` e `risk_dashboard_data.csv`
   - Correr `report_generator.py` para gerar sumarios automaticos
   - Compilar tudo em formato `board_pack_q4_2025.md`
   - Incluir seccoes: AUM, Performance, Risco, Compliance, Fees, Regulatorio
   - Enviar aos board members 2 semanas antes da reuniao

2. **Reporting Regulatorio:**
   - UCITS: Preparar dados em `ucits_reporting_data.csv` e submeter CBI Online Return
   - AIFMD: Preparar dados em `aifmd_annex_iv_data.csv` e submeter Annex IV
   - Atualizar estado em `regulatory_calendar.csv`

3. **Cristalizacao de Performance Fees:**
   - Verificar `performance_fees.csv` para fundos com cristalizacao trimestral
   - Correr `fee_validation.sql` para validar valores
   - Obter aprovacao do board

```
Fim do Trimestre:
  fund_performance_summary.csv ──┐
  risk_dashboard_data.csv ───────┤──> report_generator.py ──> board_pack.md ──> Board
  compliance_checklist.csv ──────┘

  ucits_reporting_data.csv ──────> CBI Online Return
  aifmd_annex_iv_data.csv ───────> CSSF Annex IV Submission

  performance_fees.csv ──────────> fee_validation.sql ──> Aprovacao do Board
```

### Anualmente

1. **Renovacao de KYC:** Verificar `aml_kyc_tracker.csv` para investidores com KYC a expirar
2. **Revisao da politica de compliance:** Atualizar `compliance_policy.md`
3. **KIID Updates:** Atualizar documentos-chave para investidores
4. **Contas auditadas:** Coordenar com auditores usando dados de todas as pastas

---

## Cenarios Praticos

### Cenario 1: "Recebi um email de um investidor novo que quer subscrever"

```
1. Receber pedido de subscricao
2. Abrir aml_kyc_tracker.csv
   - Investidor ja existe? Verificar estado do KYC
   - Investidor novo? Iniciar processo de onboarding
3. Se KYC = Complete e AML Risk = Low/Medium:
   - Confirmar ao relationship manager que pode prosseguir
   - Atualizar investor_register.csv com nova subscricao
4. Se KYC = Pending ou AML Risk = High:
   - Pedir documentacao adicional (Enhanced Due Diligence)
   - Consultar compliance_policy.md seccao AML/CTF
   - Nao processar subscricao ate KYC estar Complete
5. Se investidor e PEP (Politically Exposed Person):
   - Escalar para Compliance Officer
   - Documentar decisao em aml_kyc_tracker.csv
```

### Cenario 2: "O administrador publicou um NAV errado"

```
1. Detetado via nav_break_analysis.py ou manualmente
2. Registar em nav_breaks_log.csv (Status: Open)
3. Contactar administrador por email
4. Se erro confirmado pelo administrador:
   - Administrador republica NAV corrigido ("NAV restatement")
   - Atualizar nav_daily_report.csv com valor correto
   - Verificar se algum investidor foi afetado (subscricoes/resgates ao preco errado)
   - Se afetado: calcular compensacao
   - Atualizar nav_breaks_log.csv (Status: Resolved)
5. Se break e material (>0.5% do NAV):
   - Escalar para board
   - Registar em regulatory_breaches_log.csv
   - Potencial notificacao ao regulador
```

### Cenario 3: "Precisamos de lancar um fundo novo"

```
1. Abrir fund_setup_checklist.md e seguir as 4 fases:

   FASE 1 - Pre-Launch (8-12 semanas):
   - Obter aprovacao regulatoria
   - Preparar prospeto
   - Aprovacao do board

   FASE 2 - Setup (4-6 semanas):
   - Assinar acordos com service providers (administrador, custodia, auditoria)
   - Configurar sistemas (Fund Accounting System, Bloomberg)
   - Testes operacionais

   FASE 3 - Go-Live:
   - Primeiro calculo de NAV
   - Onboarding dos primeiros investidores (verificar em aml_kyc_tracker.csv)
   - Primeiras submissoes regulatorias

   FASE 4 - Post-Launch (90 dias):
   - Monitorizacao intensiva do NAV
   - Primeiro board report

2. Atualizar fund_register.csv com o novo fundo
3. Atualizar fund_structure_overview.md com a nova estrutura
4. Adicionar verificacoes em compliance_checklist.csv
5. Atualizar regulatory_calendar.csv com novas obrigacoes
```

### Cenario 4: "O regulador (CBI) pediu informacao sobre o fundo"

```
1. Consultar regulatory_calendar.csv para verificar se e um reporte standard
2. Se sim: preparar dados de ucits_reporting_data.csv ou aifmd_annex_iv_data.csv
3. Se e um pedido ad-hoc:
   - Usar investor_data_extract.sql para extrair dados de investidores
   - Usar nav_validation.sql para dados de NAV
   - Consultar regulatory_breaches_log.csv para historico de breaches
   - Compilar resposta e obter aprovacao do Compliance Officer
4. Documentar o pedido e a resposta
```

### Cenario 5: "E preciso preparar o board pack trimestral"

```
1. Duas semanas antes da reuniao do board:

   a) Performance:
      - Atualizar fund_performance_summary.csv com dados do trimestre
      - Correr report_generator.py --period Q1-2026

   b) Risco:
      - Atualizar risk_dashboard_data.csv
      - Verificar VaR, volatilidade, leverage de cada fundo

   c) Compliance:
      - Compilar todos os breaches de regulatory_breaches_log.csv do trimestre
      - Resumir estado do compliance_checklist.csv

   d) Fees:
      - Correr fee_reconciliation.sql para resumo de fees
      - Calcular TER (Total Expense Ratio) de cada fundo

   e) Investidores:
      - Correr investor_data_extract.sql para movimentos do trimestre
      - Fluxos de subscricao/resgate

   f) Regulatorio:
      - Verificar regulatory_calendar.csv para filings feitos e pendentes

2. Compilar tudo num documento seguindo o formato de board_pack_q4_2025.md
3. Enviar aos board members para revisao
4. Reuniao do board: apresentar e registar decisoes
```

---

## Glossario

| Termo | Significado |
|-------|------------|
| **NAV** | Net Asset Value - valor liquido do fundo por unidade de participacao |
| **AUM** | Assets Under Management - total de ativos geridos |
| **UCITS** | Undertakings for Collective Investment in Transferable Securities - framework regulatorio europeu para fundos de investimento |
| **AIFMD** | Alternative Investment Fund Managers Directive - regulacao para fundos alternativos |
| **ICAV** | Irish Collective Asset-management Vehicle - estrutura juridica irlandesa |
| **SICAV** | Societe d'Investissement a Capital Variable - estrutura juridica luxemburguesa |
| **KYC** | Know Your Customer - processo de identificacao e verificacao de investidores |
| **AML** | Anti-Money Laundering - prevencao de branqueamento de capitais |
| **PEP** | Politically Exposed Person - pessoa politicamente exposta |
| **HWM** | High-Water Mark - mecanismo que garante que performance fees so sao cobradas sobre novos maximos |
| **TER** | Total Expense Ratio - custo total do fundo como percentagem do AUM |
| **VaR** | Value at Risk - perda maxima esperada com um nivel de confianca |
| **CBI** | Central Bank of Ireland - regulador irlandes |
| **CSSF** | Commission de Surveillance du Secteur Financier - regulador luxemburgues |
| **ESMA** | European Securities and Markets Authority - regulador europeu |
| **BRD** | Business Requirements Document - documento de requisitos de negocio |
| **Sharpe Ratio** | Retorno ajustado ao risco - quanto retorno por unidade de risco |
| **Passive Breach** | Violacao causada por movimento de mercado, nao por acao do gestor |
| **Active Breach** | Violacao causada por uma acao deliberada (ex: compra que excede limite) |
| **NAV Break** | Discrepancia entre o NAV calculado internamente e o do administrador |
| **Cristalizacao** | Momento em que a performance fee acumulada e efetivamente cobrada |
| **Accrual** | Acumulacao diaria de um valor (fee) que sera pago posteriormente |
| **Prospeto** | Documento legal que define as regras do fundo |
| **Board Pack** | Conjunto de documentos preparados para a reuniao do conselho |
| **Factsheet** | Documento mensal resumido enviado a investidores |
| **Annex IV** | Reporte trimestral obrigatorio para fundos AIFMD |
