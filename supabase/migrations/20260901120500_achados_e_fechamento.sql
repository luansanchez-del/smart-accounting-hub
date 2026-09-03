-- Coração do fechamento contábil: achados (impedimento/alerta/informação) e
-- o registro formal do fechamento em si. A distinção de níveis é a mesma
-- definida como regra permanente do produto:
--   impedimento  -> bloqueia o fechamento, nunca pode ser só "aprovado"
--   alerta       -> exige atenção; pode ser aprovado, mas só com justificativa
--   informacao   -> evidência/observação, nunca bloqueia
-- O bloqueio de impedimento é garantido por trigger no INSERT de
-- fechamentos, não só pela tela — mesmo um bug de frontend não consegue
-- fechar uma competência com impedimento em aberto.

create table public.achados_fechamento (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  competencia_id uuid not null references public.competencias(id) on delete cascade,
  tipo text not null check (tipo in ('impedimento', 'alerta', 'informacao')),
  regra text not null,
  descricao text not null,
  conta_contabil_id uuid references public.contas_contabeis(id),
  valor numeric(16,2),
  status text not null default 'aberto' check (status in ('aberto', 'aprovado', 'resolvido')),
  justificativa text,
  documento_evidencia_id uuid references public.documentos(id),
  aprovado_por uuid references auth.users(id),
  aprovado_em timestamptz,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  -- impedimento nunca é "aprovado" por justificativa: só sai do caminho
  -- sendo corrigido na origem (status vira "resolvido").
  constraint achados_impedimento_nao_aprova check (tipo <> 'impedimento' or status <> 'aprovado'),
  -- alerta aprovado exige justificativa registrada.
  constraint achados_alerta_aprovado_exige_justificativa
    check (status <> 'aprovado' or justificativa is not null)
);

create index achados_fechamento_competencia_id_idx on public.achados_fechamento (competencia_id);
create index achados_fechamento_empresa_id_idx on public.achados_fechamento (empresa_id);

create table public.fechamentos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  competencia_id uuid not null references public.competencias(id) on delete restrict,
  total_debitos numeric(16,2) not null,
  total_creditos numeric(16,2) not null,
  quantidade_lancamentos int not null,
  resultado_liquido numeric(16,2) not null,
  total_ativo numeric(16,2) not null,
  total_passivo_pl numeric(16,2) not null,
  observacoes text,
  fechado_por uuid not null references auth.users(id),
  fechado_em timestamptz not null default now(),
  unique (competencia_id)
);

create index fechamentos_empresa_id_idx on public.fechamentos (empresa_id);

-- Trava de verdade: não deixa nascer um fechamento se existir impedimento
-- aberto (status = 'aberto') para a mesma competência.
create or replace function public.bloquear_fechamento_com_impedimento()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  qtd_impedimentos int;
begin
  select count(*) into qtd_impedimentos
  from public.achados_fechamento
  where competencia_id = new.competencia_id
    and tipo = 'impedimento'
    and status = 'aberto';

  if qtd_impedimentos > 0 then
    raise exception 'Fechamento bloqueado: % impedimento(s) em aberto na competência.', qtd_impedimentos
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

create trigger fechamentos_verificar_impedimentos
  before insert on public.fechamentos
  for each row execute function public.bloquear_fechamento_com_impedimento();

-- Ao fechar, a competência muda de status junto — mantém as duas fontes
-- (competencias.status e a existência de um fechamento) sempre coerentes.
create or replace function public.marcar_competencia_fechada()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.competencias
  set status = 'fechada', fechada_em = new.fechado_em, fechada_por = new.fechado_por
  where id = new.competencia_id;
  return new;
end;
$$;

create trigger fechamentos_marcar_competencia
  after insert on public.fechamentos
  for each row execute function public.marcar_competencia_fechada();

alter table public.achados_fechamento enable row level security;
alter table public.fechamentos enable row level security;

create policy "achados_select" on public.achados_fechamento for select to authenticated using (public.tem_permissao('fechamento', 'ver'));
create policy "achados_insert" on public.achados_fechamento for insert to authenticated with check (public.tem_permissao('fechamento', 'criar'));
create policy "achados_update" on public.achados_fechamento for update to authenticated using (public.tem_permissao('fechamento', 'editar')) with check (public.tem_permissao('fechamento', 'editar'));

-- Só quem tem "efetivar" fecha competência de verdade.
create policy "fechamentos_select" on public.fechamentos for select to authenticated using (public.tem_permissao('fechamento', 'ver'));
create policy "fechamentos_insert" on public.fechamentos for insert to authenticated with check (public.tem_permissao('fechamento', 'efetivar') and fechado_por = auth.uid());
