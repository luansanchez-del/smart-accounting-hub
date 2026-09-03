-- Motor de regras de contabilização (fase 1): transforma um documento já
-- classificado (valor + data + competência) em um lançamento automático de
-- partida dobrada simples (1 débito + 1 crédito), de forma determinística e
-- idempotente. Sem rateio/split nesta fase.
--
-- lancamentos.origem já previa 'sugerido_sistema' no seu check constraint
-- desde a migration original — esta é a peça que finalmente usa esse valor.

-- 1) Plano de contas: "dedução da receita bruta" não tinha grupo próprio e
-- cairia incorretamente em 'despesa' (ou ficaria irrepresentável). Contas
-- como "Simples Nacional a recolher" precisam desse grupo para uma futura
-- DRE calcular Receita Líquida = Receita Bruta - Deduções, e não jogar essas
-- contas lá embaixo, depois do Lucro Bruto.
alter table public.contas_contabeis drop constraint if exists contas_contabeis_grupo_check;
alter table public.contas_contabeis
  add constraint contas_contabeis_grupo_check
  check (grupo in ('ativo','passivo','patrimonio_liquido','receita','deducao_receita_bruta','despesa','custo'));

-- Toda conta de dedução de receita nasce redutora, para a futura DRE não
-- precisar adivinhar isso por convenção implícita — reaproveita o campo
-- `redutora` que já existia na tabela.
alter table public.contas_contabeis drop constraint if exists contas_contabeis_deducao_e_redutora_check;
alter table public.contas_contabeis
  add constraint contas_contabeis_deducao_e_redutora_check
  check (grupo <> 'deducao_receita_bruta' or redutora);

-- 2) Colunas mínimas em documentos para o motor poder agir: valor e data do
-- documento (o que vira o lançamento) e o estado de contabilização — evita
-- reprocessar à toa documentos sem regra e dá visibilidade de fila pra quem
-- construir a tela/rotina de disparo depois. Nenhum fluxo de classificação
-- completo nasce aqui, só o necessário pra função.
alter table public.documentos
  add column valor numeric(16,2) check (valor is null or valor > 0),
  add column data_documento date,
  add column status_contabilizacao text not null default 'pendente'
    check (status_contabilizacao in ('pendente','contabilizado','sem_regra')),
  add column updated_by uuid references auth.users(id),
  add column updated_at timestamptz not null default now();

comment on column public.documentos.valor is
  'Valor monetário do documento já classificado; precisa ser > 0 para contabilização automática.';
comment on column public.documentos.data_documento is
  'Data de emissão/referência do documento; vira data_lancamento no lançamento automático.';
comment on column public.documentos.status_contabilizacao is
  'pendente = ainda não contabilizado; contabilizado = já gerou lançamento; sem_regra = motor rodou e não achou regra ativa (fila de trabalho manual, não é erro).';

create index documentos_status_contabilizacao_pendente_idx
  on public.documentos (empresa_id)
  where status_contabilizacao = 'pendente';

create trigger documentos_auditoria before update on public.documentos
  for each row execute function public.tocar_auditoria();

-- 3) Regras determinísticas por empresa: (origem, tipo do documento) ->
-- (conta débito, conta crédito, modelo de histórico). tipo_documento NULL é
-- curinga (qualquer tipo dentro da origem).
create table public.regras_contabilizacao (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  origem_documento text not null check (origem_documento in ('upload','pier','adn_nfse','importacao','manual')),
  tipo_documento text,
  conta_debito_id uuid not null references public.contas_contabeis(id) on delete restrict,
  conta_credito_id uuid not null references public.contas_contabeis(id) on delete restrict,
  modelo_historico text not null default '',
  ativa boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  constraint regras_contabilizacao_contas_distintas check (conta_debito_id <> conta_credito_id)
);

create index regras_contabilizacao_empresa_id_idx on public.regras_contabilizacao (empresa_id);

-- Uma regra ativa por (empresa, origem, tipo); coalesce trata o curinga
-- (tipo_documento NULL) como chave própria — senão o unique padrão deixaria
-- múltiplos NULLs "colidirem invisivelmente" (NULL <> NULL para unicidade).
create unique index regras_contabilizacao_chave_ativa_idx
  on public.regras_contabilizacao (empresa_id, origem_documento, coalesce(tipo_documento, ''))
  where ativa;

alter table public.regras_contabilizacao enable row level security;

create policy "regras_contabilizacao_select" on public.regras_contabilizacao for select to authenticated using (public.tem_permissao('lancamentos','ver'));
create policy "regras_contabilizacao_insert" on public.regras_contabilizacao for insert to authenticated with check (public.tem_permissao('lancamentos','criar') and created_by = auth.uid());
create policy "regras_contabilizacao_update" on public.regras_contabilizacao for update to authenticated using (public.tem_permissao('lancamentos','editar')) with check (public.tem_permissao('lancamentos','editar'));

create trigger regras_contabilizacao_auditoria before update on public.regras_contabilizacao
  for each row execute function public.tocar_auditoria();

comment on table public.regras_contabilizacao is
  'Regras determinísticas empresa->documento->partida dobrada usadas por contabilizar_documento(). Fase 1: 1 débito + 1 crédito, sem rateio/split.';
comment on column public.regras_contabilizacao.tipo_documento is
  'NULL = curinga (qualquer tipo dentro da origem); regra com tipo exato tem prioridade sobre a curinga na busca.';
comment on column public.regras_contabilizacao.modelo_historico is
  'Texto usado como historico do lançamento gerado; vazio cai no nome do arquivo do documento.';

-- Integridade: a regra precisa apontar para contas ATIVAS da MESMA empresa
-- (FK simples não garante isso — só garante que a conta existe em algum
-- lugar). Sem isso, um erro de cadastro geraria lançamento cruzando
-- empresas ou usando conta desativada, sem nenhum aviso.
create or replace function public.validar_regra_contabilizacao()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.contas_contabeis
    where id = new.conta_debito_id and empresa_id = new.empresa_id and ativa
  ) then
    raise exception 'Conta débito % não pertence à empresa % ou está inativa.', new.conta_debito_id, new.empresa_id;
  end if;

  if not exists (
    select 1 from public.contas_contabeis
    where id = new.conta_credito_id and empresa_id = new.empresa_id and ativa
  ) then
    raise exception 'Conta crédito % não pertence à empresa % ou está inativa.', new.conta_credito_id, new.empresa_id;
  end if;

  return new;
end;
$$;

create trigger regras_contabilizacao_validar_contas
  before insert or update on public.regras_contabilizacao
  for each row execute function public.validar_regra_contabilizacao();

-- 4) Guarda-corpo de idempotência a nível de banco: nunca mais de um
-- lançamento AUTOMÁTICO (origem = sugerido_sistema) para o mesmo documento,
-- mesmo sob concorrência. Não restringe lançamentos manuais que também
-- referenciem o mesmo documento como comprovante — isso já é um uso
-- legítimo hoje.
create unique index lancamentos_documento_sugerido_sistema_idx
  on public.lancamentos (documento_id)
  where origem = 'sugerido_sistema' and documento_id is not null;

-- 5) A função. security definer + checagem manual de permissão: o mesmo
-- padrão dos triggers de fechamento (bloquear_fechamento_com_impedimento,
-- marcar_competencia_fechada) — como função security definer já ignora a
-- RLS de lancamentos/partidas, a permissão de verdade é validada aqui.
create or replace function public.contabilizar_documento(p_documento_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_documento public.documentos%rowtype;
  v_competencia public.competencias%rowtype;
  v_regra public.regras_contabilizacao%rowtype;
  v_lancamento_id uuid;
  v_historico text;
begin
  if not public.tem_permissao('lancamentos', 'criar') then
    raise exception 'Sem permissão para contabilizar documentos.'
      using errcode = 'insufficient_privilege';
  end if;

  -- Lock de linha primeiro, idempotência depois: serializa chamadas
  -- concorrentes para o MESMO documento — a segunda espera a primeira
  -- commitar e aí enxerga o lançamento já criado, devolvendo o id existente
  -- em vez de duplicar. O índice único do passo 4 é a segunda linha de
  -- defesa para qualquer caminho que não passe por esta função.
  select * into v_documento from public.documentos where id = p_documento_id for update;
  if not found then
    raise exception 'Documento % não encontrado.', p_documento_id;
  end if;

  select id into v_lancamento_id
  from public.lancamentos
  where documento_id = p_documento_id and origem = 'sugerido_sistema'
  limit 1;
  if v_lancamento_id is not null then
    return v_lancamento_id;
  end if;

  if v_documento.valor is null or v_documento.valor <= 0 then
    raise exception 'Documento % precisa de valor classificado (maior que zero) antes de ser contabilizado.', p_documento_id;
  end if;

  if v_documento.data_documento is null then
    raise exception 'Documento % precisa de data_documento preenchida antes de ser contabilizado.', p_documento_id;
  end if;

  if v_documento.competencia_id is null then
    raise exception 'Documento % precisa estar vinculado a uma competência antes de ser contabilizado.', p_documento_id;
  end if;

  -- for share prende a competência contra um fechamento concorrente
  -- (fechamentos -> trigger marcar_competencia_fechada) até este lançamento
  -- terminar: ou o fechamento espera, ou aqui já vê 'fechada' e bloqueia.
  select * into v_competencia from public.competencias where id = v_documento.competencia_id for share;
  if v_competencia.status = 'fechada' then
    raise exception 'Competência % já está fechada; reabra-a antes de contabilizar este documento.', v_documento.competencia_id
      using errcode = 'check_violation';
  end if;

  select *
  into v_regra
  from public.regras_contabilizacao
  where empresa_id = v_documento.empresa_id
    and origem_documento = v_documento.origem
    and ativa
    and (tipo_documento = v_documento.tipo or tipo_documento is null)
  order by tipo_documento nulls last
  limit 1;

  if not found then
    -- Não é erro: documento sem regra é fila de trabalho manual (revisão
    -- de cadastro de regra), não falha de sistema.
    update public.documentos set status_contabilizacao = 'sem_regra' where id = p_documento_id;
    return null;
  end if;

  v_historico := nullif(v_regra.modelo_historico, '');
  if v_historico is null then
    v_historico := v_documento.nome_arquivo;
  end if;

  insert into public.lancamentos (
    empresa_id, competencia_id, data_lancamento, historico, documento_id, origem, created_by
  ) values (
    v_documento.empresa_id, v_documento.competencia_id, v_documento.data_documento, v_historico,
    v_documento.id, 'sugerido_sistema', v_documento.created_by
  )
  returning id into v_lancamento_id;

  insert into public.partidas (lancamento_id, conta_contabil_id, tipo, valor) values
    (v_lancamento_id, v_regra.conta_debito_id, 'debito', v_documento.valor),
    (v_lancamento_id, v_regra.conta_credito_id, 'credito', v_documento.valor);

  update public.documentos set status_contabilizacao = 'contabilizado' where id = p_documento_id;

  return v_lancamento_id;
end;
$$;

comment on function public.contabilizar_documento(uuid) is
  'Motor de contabilização automática fase 1: documento classificado -> 1 lançamento (origem=sugerido_sistema) + 2 partidas via regras_contabilizacao. Idempotente; retorna null (sem lançar exceção) quando não há regra ativa.';
