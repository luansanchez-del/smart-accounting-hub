-- Piloto: AMA CLÍNICA DE SAÚDE LTDA (CNPJ 05.645.629/0001-02).
-- Dado de UM cliente específico, não é mudança de schema — roda uma vez via
-- SQL Editor do Supabase/Lovable Cloud, não entra em supabase/migrations/.
-- Rode DEPOIS de supabase/migrations/20260903090000_motor_contabilizacao.sql
-- (depende do grupo 'deducao_receita_bruta' que essa migration cria).
--
-- Fontes:
--   - Balancete Group Legacy, período 01/01/2026 a 31/08/2026 (PDF).
--   - ExportacaoClientes (PIER), aba Clientes, linha ID 10 — cadastro
--     (município/UF/CNAE/tributação) que o balancete não traz.
--
-- Saldo de implantação = coluna "Saldo Anterior" do balancete = saldo de
-- abertura em 31/12/2025 (início do período coberto pelo relatório).
--
-- Duas contas foram reclassificadas em relação à hierarquia VISUAL do
-- balancete de origem, pra caber corretamente no nosso plano de contas
-- (grupo é uma classificação plana por conta, não herdada da árvore):
--   - "PATRIMÔNIO LÍQUIDO" (código 2325) virou raiz própria (grupo
--     patrimonio_liquido) em vez de filha de "PASSIVO" (código 1350) — no
--     balancete de origem os dois aparecem juntos só por layout de
--     relatório, mas Ativo = Passivo + PL exige que sejam categorias
--     irmãs, nunca uma dentro da outra.
--   - "RECEITAS FINANCEIRAS" (código 4923) virou filha de "RECEITAS"
--     (código 2600) em vez de filha de "DESPESAS OPERACIONAIS" (código
--     4011) — é receita, não pode entrar no grupo despesa só porque o
--     relatório de origem mostra o resultado financeiro líquido dentro do
--     bloco de despesas.
--
-- "Salários e Ordenados" (código 4328): Saldo Anterior do balancete vem
-- negativo, (0,44) — sinal contrário ao normal de uma despesa. Gravado
-- aqui como valor=0.44 / natureza_saldo='credor', a exceção real desse
-- saldo específico (a conta em si continua natureza='devedora', que é o
-- normal esperado pra uma despesa).
--
-- Conferência contra a DRE 2025 (Group Legacy) revelou duas coisas que o
-- balancete sozinho não mostrava:
--   - Conta 3127 "INSS", classificada como CUSTO (grupo='custo', nenhuma
--     outra conta desta empresa usava esse grupo até então), R$ 440,00 —
--     estava faltando no plano de contas montado só a partir do balancete.
--   - O lucro de 2025 (R$ 30.737,52, igual ao "LUCRO LÍQUIDO DO EXERCÍCIO"
--     da DRE 2025 E exatamente igual à diferença Ativo≠Passivo+PL que
--     esse script tinha antes desse ajuste) nunca tinha sido zerado contra
--     o Patrimônio Líquido. Confirmado pelo usuário que o zeramento já foi
--     feito no sistema de origem, com data 30/06/2025 — este script grava
--     esse valor como uma conta própria e documentada em PL
--     ("AJUSTE-ZERAMENTO-2025"), datada 30/06/2025 (não 31/12/2025 como o
--     resto do saldo de implantação), e não mistura com "(-) Prejuízos
--     Acumulados" (que são perdas de exercícios anteriores, sem relação
--     com este lucro de 2025). Com isso, Ativo = Passivo + PL bate
--     exatamente (35.491,55 = 35.491,55).
--
--   O INSS (conta 3127, R$ 440,00) é custo já fechado dentro do resultado
--   de 2025 — está embutido no R$ 30.737,52 acima, então a conta entra no
--   plano de contas (pra receber lançamentos novos a partir de 2026) mas
--   SEM saldo de implantação próprio, pra não contar o mesmo valor duas
--   vezes.
--
--   Ponto em aberto, não resolvido aqui: as outras contas de Receita/
--   Despesa importadas abaixo (Pró Labore, Despesas Bancárias, Simples
--   Nacional etc.) vêm do "Saldo Anterior" do balancete Jan-Ago/2026, que
--   pra contas de resultado normalmente significa acumulado DENTRO do ano
--   corrente (não um saldo que atravessa virada de ano, já que resultado
--   zera todo início de exercício) — mesma lógica do zeramento acima. Não
--   foi confirmado ainda com que data/período elas realmente se referem;
--   ficaram como estavam (datadas 31/12/2025, mesma data do restante).
--
-- Script roda uma única vez. Pra rodar de novo, apague antes as linhas
-- desta empresa (contas_contabeis em cascade apaga saldos_implantacao).

begin;

create temporary table _import_contas (
  codigo text primary key,
  id uuid not null default gen_random_uuid()
) on commit drop;

-- 1) Empresa -----------------------------------------------------------
insert into public.empresas (
  codigo, cnpj, tipo, razao_social, nome_fantasia, municipio, uf, cnae,
  atividade, regime, regime_confirmado
) values (
  '0010', '05645629000102', 'matriz', 'AMA CLÍNICA DE SAÚDE LTDA', 'AMA CLÍNICA DE SAÚDE LTDA',
  'Curitiba', 'PR', '8630-5/03', 'Serviço', 'simples', true
);

-- 2) Plano de contas -----------------------------------------------------
-- Reserva os ids na tabela temporária antes de inserir, pra poder
-- referenciar conta_pai_id mesmo apontando pra um código que ainda não
-- existe na tabela real.
insert into _import_contas (codigo) values
  ('1'),('2'),('3'),('4'),('4859'),('6'),('23'),('157'),('359'),('4898'),
  ('380'),('388'),('590'),('969'),('990'),('25005'),('1074'),('1089'),
  ('1136'),('1153'),
  ('1350'),('1351'),('1539'),('1540'),('1544'),('1632'),('1633'),('1635'),
  ('1658'),('1659'),('1710'),('1711'),('1712'),('4866'),('4899'),
  ('2325'),('2346'),('2347'),('25002'),('25003'),('25004'),('2513'),
  ('2514'),('2516'),('2537'),('2539'),
  ('2600'),('2601'),('2602'),('2700'),('2701'),('2703'),('2770'),('2825'),
  ('2831'),('4923'),('4924'),('4926'),('5739'),
  ('3000'),('4011'),('4012'),('4239'),('4248'),('4326'),('4327'),('4328'),
  ('4329'),('4531'),('4537'),('4695'),('4696'),('4936'),('5072'),('4701'),
  ('3127'),('AJUSTE-ZERAMENTO-2025');

insert into public.contas_contabeis (id, empresa_id, codigo, descricao, tipo, natureza, grupo, conta_pai_id, redutora)
select
  m.id,
  (select id from public.empresas where cnpj = '05645629000102'),
  v.codigo, v.descricao, v.tipo, v.natureza, v.grupo, p.id, v.redutora
from (values
  -- ATIVO
  ('1',     'ATIVO',                                             'sintetica', 'devedora', 'ativo',               null,   false),
  ('2',     'CIRCULANTE',                                        'sintetica', 'devedora', 'ativo',               '1',    false),
  ('3',     'DISPONÍVEL',                                        'sintetica', 'devedora', 'ativo',               '2',    false),
  ('4',     'BENS NUMERÁRIOS',                                   'sintetica', 'devedora', 'ativo',               '3',    false),
  ('4859',  'Conta Transitória',                                 'analitica', 'devedora', 'ativo',               '4',    false),
  ('6',     'DEPÓSITOS BANCÁRIOS A VISTA',                       'sintetica', 'devedora', 'ativo',               '3',    false),
  ('23',    'Banco Sicredi',                                     'analitica', 'devedora', 'ativo',               '6',    false),
  ('157',   'OUTROS CRÉDITOS',                                   'sintetica', 'devedora', 'ativo',               '2',    false),
  ('359',   'LUCROS DISTRIBUIDOS NO EXERCÍCIO',                  'sintetica', 'devedora', 'ativo',               '157',  false),
  ('4898',  'Adiantamento de Lucros',                            'analitica', 'devedora', 'ativo',               '359',  false),
  ('380',   'TRIBUTOS A RECUPERAR',                               'sintetica', 'devedora', 'ativo',               '157',  false),
  ('388',   'INSS a Recuperar',                                  'analitica', 'devedora', 'ativo',               '380',  false),
  ('590',   'NÃO CIRCULANTE',                                    'sintetica', 'devedora', 'ativo',               '1',    false),
  ('969',   'INVESTIMENTOS',                                     'sintetica', 'devedora', 'ativo',               '590',  false),
  ('990',   'PARTIC. PERMANENTES OUTRAS SOCIEDADES',              'sintetica', 'devedora', 'ativo',               '969',  false),
  ('25005', 'SICREDI',                                           'analitica', 'devedora', 'ativo',               '990',  false),
  ('1074',  'BENS EM OPERAÇÃO',                                  'sintetica', 'devedora', 'ativo',               '590',  false),
  ('1089',  'Veículos',                                          'analitica', 'devedora', 'ativo',               '1074', false),
  ('1136',  '(-) DEPRECIAÇÃO/AMORTIZAÇÃO/EXAUSTÃO ACUMULADA',    'sintetica', 'credora',  'ativo',               '590',  true),
  ('1153',  '(-) Deprec. Veículos',                              'analitica', 'credora',  'ativo',               '1136', true),
  -- PASSIVO
  ('1350',  'PASSIVO',                                           'sintetica', 'credora',  'passivo',             null,   false),
  ('1351',  'CIRCULANTE',                                        'sintetica', 'credora',  'passivo',             '1350', false),
  ('1539',  'OBRIGAÇÕES TRIBUTÁRIAS',                            'sintetica', 'credora',  'passivo',             '1351', false),
  ('1540',  'IMPOSTOS E CONTRIBUIÇÕES A RECOLHER',                'sintetica', 'credora',  'passivo',             '1539', false),
  ('1544',  'IRRF sobre Trabalho Assalariado',                   'analitica', 'credora',  'passivo',             '1540', false),
  ('1632',  'OBRIGAÇÕES TRABALHISTAS E PRIVIDENCIÁRIAS',         'sintetica', 'credora',  'passivo',             '1351', false),
  ('1633',  'OBRIGAÇÕES COM O PESSOAL',                          'sintetica', 'credora',  'passivo',             '1632', false),
  ('1635',  'Pró Labore a Pagar',                                'analitica', 'credora',  'passivo',             '1633', false),
  ('1658',  'OBRIGAÇÕES PREVIDENCIÁRIAS',                        'sintetica', 'credora',  'passivo',             '1632', false),
  ('1659',  'INSS a Recolher',                                   'analitica', 'credora',  'passivo',             '1658', false),
  ('1710',  'OUTRAS OBRIGAÇÕES',                                 'sintetica', 'credora',  'passivo',             '1351', false),
  ('1711',  'ADIANTAMENTOS DE CLIENTES',                         'sintetica', 'credora',  'passivo',             '1710', false),
  ('1712',  'Adiantamentos de Clientes Diversos',                'analitica', 'credora',  'passivo',             '1711', false),
  ('4866',  'OUTROS EMPRÉSTIMOS',                                'sintetica', 'credora',  'passivo',             '1710', false),
  ('4899',  'Empréstimo de Sócios',                              'analitica', 'credora',  'passivo',             '4866', false),
  -- PATRIMÔNIO LÍQUIDO (reparentado pra raiz própria — ver nota no topo)
  ('2325',  'PATRIMÔNIO LÍQUIDO',                                'sintetica', 'credora',  'patrimonio_liquido',  null,   false),
  ('2346',  'CAPITAL SOCIAL',                                    'sintetica', 'credora',  'patrimonio_liquido',  '2325', false),
  ('2347',  'CAPITAL SUBSCRITO',                                 'sintetica', 'credora',  'patrimonio_liquido',  '2346', false),
  ('25002', 'Ana Paula Ferraz Dondoni',                          'analitica', 'credora',  'patrimonio_liquido',  '2347', false),
  ('25003', 'Maria de Fátima Borges Vieira',                     'analitica', 'credora',  'patrimonio_liquido',  '2347', false),
  ('25004', 'Roque Dondoni',                                     'analitica', 'credora',  'patrimonio_liquido',  '2347', false),
  ('2513',  'LUCROS E PREJUÍZOS ACUMULADOS',                     'sintetica', 'devedora', 'patrimonio_liquido',  '2325', true),
  ('2514',  'LUCROS E PREJUÍZOS ACUMULADOS',                     'sintetica', 'devedora', 'patrimonio_liquido',  '2513', true),
  ('2516',  '(-) Prejuízos Acumulados',                          'analitica', 'devedora', 'patrimonio_liquido',  '2514', true),
  ('2537',  'LUCROS E PREJUÍZOS DO EXERCÍCIO',                   'sintetica', 'devedora', 'patrimonio_liquido',  '2513', true),
  ('2539',  '(-) Prejuízos do Exercício',                        'analitica', 'devedora', 'patrimonio_liquido',  '2537', true),
  ('AJUSTE-ZERAMENTO-2025', 'Lucros Acumulados — zeramento exercício 2025 (ajuste de implantação, 30/06/2025)', 'analitica', 'credora', 'patrimonio_liquido', '2513', false),
  -- RECEITAS
  ('2600',  'RECEITAS',                                          'sintetica', 'credora',  'receita',             null,   false),
  ('2601',  'RECEITAS OPERACIONAIS',                             'sintetica', 'credora',  'receita',             '2600', false),
  ('2602',  'RECEITA BRUTA DE VENDAS E SERVIÇOS',                'sintetica', 'credora',  'receita',             '2601', false),
  ('2700',  'PRESTAÇÃO DE SERVIÇOS',                             'sintetica', 'credora',  'receita',             '2602', false),
  ('2701',  'SERVIÇOS MERCADO INTERNO',                          'sintetica', 'credora',  'receita',             '2700', false),
  ('2703',  'Prestação de Serviços a Prazo',                     'analitica', 'credora',  'receita',             '2701', false),
  ('2770',  '(-) DEDUÇÕES DA RECEITA BRUTA',                     'sintetica', 'devedora', 'deducao_receita_bruta','2601', true),
  ('2825',  '(-) IMPOSTOS INCIDENTES SOBRE VENDAS',               'sintetica', 'devedora', 'deducao_receita_bruta','2770', true),
  ('2831',  '(-) Simples Nacional',                              'analitica', 'devedora', 'deducao_receita_bruta','2825', true),
  ('4923',  'RECEITAS FINANCEIRAS',                              'sintetica', 'credora',  'receita',             '2600', false),
  ('4924',  'RECEITAS FINANCEIRAS',                              'sintetica', 'credora',  'receita',             '4923', false),
  ('4926',  'Rendimentos de Aplicação Financeira',                'analitica', 'credora',  'receita',             '4924', false),
  ('5739',  'Variações Monetárias Ativas',                       'analitica', 'credora',  'receita',             '4924', false),
  -- CUSTOS E DESPESAS
  ('3000',  'CUSTOS E DESPESAS',                                 'sintetica', 'devedora', 'despesa',             null,   false),
  ('4011',  'DESPESAS OPERACIONAIS',                             'sintetica', 'devedora', 'despesa',             '3000', false),
  ('4012',  'DESPESAS GERAIS',                                   'sintetica', 'devedora', 'despesa',             '4011', false),
  ('4239',  'DESPESAS GERAIS',                                   'sintetica', 'devedora', 'despesa',             '4012', false),
  ('4248',  'Locação de Máquinas e Equipamentos',                'analitica', 'devedora', 'despesa',             '4239', false),
  ('4326',  'DESPESAS ADMINISTRATIVAS',                          'sintetica', 'devedora', 'despesa',             '4011', false),
  ('4327',  'DESPESAS COM PESSOAL',                               'sintetica', 'devedora', 'despesa',             '4326', false),
  ('4328',  'Salários e Ordenados',                              'analitica', 'devedora', 'despesa',             '4327', false),
  ('4329',  'Pró Labore',                                        'analitica', 'devedora', 'despesa',             '4327', false),
  ('4531',  'DESPESAS GERAIS',                                   'sintetica', 'devedora', 'despesa',             '4326', false),
  ('4537',  'Serviços Profissionais',                            'analitica', 'devedora', 'despesa',             '4531', false),
  ('4695',  'DESPESAS FINANCEIRAS',                               'sintetica', 'devedora', 'despesa',             '4011', false),
  ('4696',  'DESPESAS GERAIS',                                   'sintetica', 'devedora', 'despesa',             '4695', false),
  ('4936',  'Despesas Bancárias',                                'analitica', 'devedora', 'despesa',             '4696', false),
  ('5072',  'IOF',                                                'analitica', 'devedora', 'despesa',             '4696', false),
  ('4701',  'Juros Pagos ou Incorridos',                         'analitica', 'devedora', 'despesa',             '4696', false),
  -- CUSTO (revelado pela DRE 2025; não aparecia no balancete Jan-Ago/2026)
  ('3127',  'INSS',                                              'analitica', 'devedora', 'custo',               '3000', false)
) as v(codigo, descricao, tipo, natureza, grupo, pai_codigo, redutora)
join _import_contas m on m.codigo = v.codigo
left join _import_contas p on p.codigo = v.pai_codigo;

-- 3) Saldos de implantação (Saldo Anterior, 31/12/2025) -------------------
-- Só contas analíticas recebem saldo — contas sintéticas são só
-- agrupadoras de relatório, nunca pontos de lançamento/saldo.
insert into public.saldos_implantacao (empresa_id, conta_contabil_id, data_referencia, valor, natureza_saldo, observacoes)
select
  (select id from public.empresas where cnpj = '05645629000102'),
  m.id, '2025-12-31', v.valor, v.natureza_saldo,
  'Saldo de implantação — balancete Group Legacy, Saldo Anterior (31/12/2025).'
from (values
  ('4859',  359.84,     'devedor'),
  ('23',    8740.06,    'devedor'),
  ('4898',  26032.42,   'devedor'),
  ('388',   229.42,     'devedor'),
  ('25005', 129.81,     'devedor'),
  ('1089',  67408.60,   'devedor'),
  ('1153',  67408.60,   'credor'),
  ('1544',  344.28,     'credor'),
  ('1635',  3445.00,    'credor'),
  ('1659',  439.99,     'credor'),
  ('1712',  514.76,     'credor'),
  ('4899',  102281.49,  'credor'),
  ('25002', 3333.33,    'credor'),
  ('25003', 3333.33,    'credor'),
  ('25004', 3333.34,    'credor'),
  ('2516',  109512.43,  'devedor'),
  ('2539',  2759.06,    'devedor'),
  ('2703',  63050.00,   'credor'),
  ('2831',  6885.13,    'devedor'),
  ('4926',  9.63,       'credor'),
  ('5739',  4.75,       'credor'),
  ('4248',  63.87,      'devedor'),
  ('4328',  0.44,       'credor'),
  ('4329',  24000.00,   'devedor'),
  ('4537',  430.00,     'devedor'),
  ('4936',  293.96,     'devedor'),
  ('5072',  0.65,       'devedor'),
  ('4701',  213.69,     'devedor')
) as v(codigo, valor, natureza_saldo)
join _import_contas m on m.codigo = v.codigo;

-- Ajuste de zeramento do exercício 2025 — data e observação próprias,
-- separado do resto (ver nota no topo do arquivo).
insert into public.saldos_implantacao (empresa_id, conta_contabil_id, data_referencia, valor, natureza_saldo, observacoes)
select
  (select id from public.empresas where cnpj = '05645629000102'),
  m.id, '2025-06-30', 30737.52, 'credor',
  'Zeramento do resultado do exercício 2025 (Receita líquida 56.164,87 − Custo INSS 440,00 − Despesas 24.987,35 + Receitas financeiras 14,38 = 30.737,52, confirmado contra a DRE 2025 da Group Legacy). Sem esse lançamento, Ativo não batia com Passivo+PL no balancete de origem.'
from _import_contas m
where m.codigo = 'AJUSTE-ZERAMENTO-2025';

commit;
