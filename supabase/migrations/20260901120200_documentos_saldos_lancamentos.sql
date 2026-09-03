-- Rastreabilidade de origem (documentos/importações), saldos de implantação
-- (nunca viram lançamento comum) e o motor de partidas dobradas
-- (lançamentos + partidas). Lançamentos não têm policy de delete: correção
-- é sempre por estorno auditável (estornado_por_id), nunca exclusão física.

create table public.documentos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  competencia_id uuid references public.competencias(id) on delete set null,
  nome_arquivo text not null,
  tipo text,
  origem text not null default 'upload' check (origem in ('upload','pier','importacao','manual')),
  storage_path text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index documentos_empresa_id_idx on public.documentos (empresa_id);

create table public.importacoes (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  tipo text not null,
  status text not null default 'pendente' check (status in ('pendente','processando','concluida','erro')),
  documento_id uuid references public.documentos(id) on delete set null,
  detalhes jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table public.saldos_implantacao (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  conta_contabil_id uuid not null references public.contas_contabeis(id) on delete restrict,
  data_referencia date not null,
  valor numeric(16,2) not null,
  natureza_saldo text not null check (natureza_saldo in ('devedor','credor')),
  documento_id uuid references public.documentos(id),
  observacoes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index saldos_implantacao_empresa_id_idx on public.saldos_implantacao (empresa_id);

create table public.lancamentos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  competencia_id uuid not null references public.competencias(id) on delete restrict,
  data_lancamento date not null,
  historico text not null,
  documento_id uuid references public.documentos(id),
  origem text not null default 'manual' check (origem in ('manual','importado','derivado','sugerido_sistema','ajuste_manual')),
  status text not null default 'ativo' check (status in ('ativo','estornado')),
  estornado_por_id uuid references public.lancamentos(id),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index lancamentos_empresa_id_idx on public.lancamentos (empresa_id);
create index lancamentos_competencia_id_idx on public.lancamentos (competencia_id);

create table public.partidas (
  id uuid primary key default gen_random_uuid(),
  lancamento_id uuid not null references public.lancamentos(id) on delete cascade,
  conta_contabil_id uuid not null references public.contas_contabeis(id) on delete restrict,
  centro_custo_id uuid references public.centros_custo(id),
  tipo text not null check (tipo in ('debito','credito')),
  valor numeric(16,2) not null check (valor > 0),
  created_at timestamptz not null default now()
);

create index partidas_lancamento_id_idx on public.partidas (lancamento_id);
create index partidas_conta_contabil_id_idx on public.partidas (conta_contabil_id);
create index partidas_centro_custo_id_idx on public.partidas (centro_custo_id);

alter table public.documentos enable row level security;
alter table public.importacoes enable row level security;
alter table public.saldos_implantacao enable row level security;
alter table public.lancamentos enable row level security;
alter table public.partidas enable row level security;

create policy "documentos_select" on public.documentos for select to authenticated using (public.tem_permissao('documentos','ver'));
create policy "documentos_insert" on public.documentos for insert to authenticated with check (public.tem_permissao('documentos','criar') and created_by = auth.uid());
create policy "documentos_update" on public.documentos for update to authenticated using (public.tem_permissao('documentos','editar')) with check (public.tem_permissao('documentos','editar'));
create policy "documentos_delete" on public.documentos for delete to authenticated using (public.tem_permissao('documentos','excluir'));

create policy "importacoes_select" on public.importacoes for select to authenticated using (public.tem_permissao('documentos','ver'));
create policy "importacoes_insert" on public.importacoes for insert to authenticated with check (public.tem_permissao('documentos','criar'));
create policy "importacoes_update" on public.importacoes for update to authenticated using (public.tem_permissao('documentos','editar')) with check (public.tem_permissao('documentos','editar'));

create policy "saldos_implantacao_select" on public.saldos_implantacao for select to authenticated using (public.tem_permissao('lancamentos','ver'));
create policy "saldos_implantacao_insert" on public.saldos_implantacao for insert to authenticated with check (public.tem_permissao('lancamentos','criar') and created_by = auth.uid());
create policy "saldos_implantacao_update" on public.saldos_implantacao for update to authenticated using (public.tem_permissao('lancamentos','editar')) with check (public.tem_permissao('lancamentos','editar'));

-- Sem policy de delete/update de status aqui: lançamento efetivado só é
-- corrigido por estorno (novo lançamento com estornado_por_id apontando
-- para o original), nunca por UPDATE/DELETE direto da linha original.
create policy "lancamentos_select" on public.lancamentos for select to authenticated using (public.tem_permissao('lancamentos','ver'));
create policy "lancamentos_insert" on public.lancamentos for insert to authenticated with check (public.tem_permissao('lancamentos','criar') and created_by = auth.uid());

create policy "partidas_select" on public.partidas for select to authenticated using (public.tem_permissao('lancamentos','ver'));
create policy "partidas_insert" on public.partidas for insert to authenticated with check (public.tem_permissao('lancamentos','criar'));
