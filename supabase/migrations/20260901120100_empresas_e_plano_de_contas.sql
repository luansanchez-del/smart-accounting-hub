-- Núcleo multiempresa: grupos econômicos, empresas, competências e plano de
-- contas (próprio por empresa + plano referencial com vínculos versionados
-- por vigência, para futura compatibilidade com sistemas como o Questor).

create table public.grupos_economicos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  created_at timestamptz not null default now()
);

create table public.empresas (
  id uuid primary key default gen_random_uuid(),
  codigo text not null,
  cnpj text not null unique,
  tipo text not null check (tipo in ('matriz','filial')),
  razao_social text not null,
  nome_fantasia text not null default '',
  municipio text not null default '',
  uf text not null,
  cnae text,
  atividade text,
  regime text not null check (regime in ('simples','presumido','real','imune','isenta','mei')),
  regime_confirmado boolean not null default false,
  grupo_id uuid references public.grupos_economicos(id) on delete set null,
  ativa boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

create index empresas_grupo_id_idx on public.empresas (grupo_id);

create table public.competencias (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  ano int not null,
  mes int not null check (mes between 1 and 12),
  status text not null default 'aberta' check (status in ('aberta','em_fechamento','fechada','reaberta')),
  fechada_em timestamptz,
  fechada_por uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (empresa_id, ano, mes)
);

create index competencias_empresa_id_idx on public.competencias (empresa_id);

create table public.contas_contabeis (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  codigo text not null,
  descricao text not null,
  tipo text not null check (tipo in ('sintetica','analitica')),
  natureza text not null check (natureza in ('devedora','credora')),
  grupo text not null check (grupo in ('ativo','passivo','patrimonio_liquido','receita','despesa','custo')),
  conta_pai_id uuid references public.contas_contabeis(id),
  redutora boolean not null default false,
  ativa boolean not null default true,
  created_at timestamptz not null default now(),
  unique (empresa_id, codigo)
);

create index contas_contabeis_empresa_id_idx on public.contas_contabeis (empresa_id);

create table public.centros_custo (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  codigo text not null,
  descricao text not null,
  ativo boolean not null default true,
  created_at timestamptz not null default now(),
  unique (empresa_id, codigo)
);

create index centros_custo_empresa_id_idx on public.centros_custo (empresa_id);

create table public.contas_referenciais (
  id uuid primary key default gen_random_uuid(),
  codigo text not null unique,
  descricao text not null,
  origem text not null default 'questor',
  created_at timestamptz not null default now()
);

create table public.vinculos_referenciais (
  id uuid primary key default gen_random_uuid(),
  conta_contabil_id uuid not null references public.contas_contabeis(id) on delete cascade,
  conta_referencial_id uuid not null references public.contas_referenciais(id) on delete restrict,
  vigencia_inicio date not null,
  vigencia_fim date,
  created_at timestamptz not null default now()
);

create index vinculos_referenciais_conta_contabil_id_idx on public.vinculos_referenciais (conta_contabil_id);

alter table public.grupos_economicos enable row level security;
alter table public.empresas enable row level security;
alter table public.competencias enable row level security;
alter table public.contas_contabeis enable row level security;
alter table public.centros_custo enable row level security;
alter table public.contas_referenciais enable row level security;
alter table public.vinculos_referenciais enable row level security;

create policy "grupos_select" on public.grupos_economicos for select to authenticated using (public.tem_permissao('empresas','ver'));
create policy "grupos_insert" on public.grupos_economicos for insert to authenticated with check (public.tem_permissao('empresas','criar'));
create policy "grupos_update" on public.grupos_economicos for update to authenticated using (public.tem_permissao('empresas','editar')) with check (public.tem_permissao('empresas','editar'));

create policy "empresas_select" on public.empresas for select to authenticated using (public.tem_permissao('empresas','ver'));
create policy "empresas_insert" on public.empresas for insert to authenticated with check (public.tem_permissao('empresas','criar') and created_by = auth.uid());
create policy "empresas_update" on public.empresas for update to authenticated using (public.tem_permissao('empresas','editar')) with check (public.tem_permissao('empresas','editar'));
create policy "empresas_delete" on public.empresas for delete to authenticated using (public.tem_permissao('empresas','excluir'));
create trigger empresas_auditoria before update on public.empresas for each row execute function public.tocar_auditoria();

create policy "competencias_select" on public.competencias for select to authenticated using (public.tem_permissao('empresas','ver'));
create policy "competencias_insert" on public.competencias for insert to authenticated with check (public.tem_permissao('empresas','criar'));
create policy "competencias_update" on public.competencias for update to authenticated using (public.tem_permissao('fechamento','editar') or public.tem_permissao('fechamento','efetivar')) with check (public.tem_permissao('fechamento','editar') or public.tem_permissao('fechamento','efetivar'));

create policy "contas_contabeis_select" on public.contas_contabeis for select to authenticated using (public.tem_permissao('empresas','ver'));
create policy "contas_contabeis_insert" on public.contas_contabeis for insert to authenticated with check (public.tem_permissao('empresas','criar'));
create policy "contas_contabeis_update" on public.contas_contabeis for update to authenticated using (public.tem_permissao('empresas','editar')) with check (public.tem_permissao('empresas','editar'));

create policy "centros_custo_select" on public.centros_custo for select to authenticated using (public.tem_permissao('empresas','ver'));
create policy "centros_custo_insert" on public.centros_custo for insert to authenticated with check (public.tem_permissao('empresas','criar'));
create policy "centros_custo_update" on public.centros_custo for update to authenticated using (public.tem_permissao('empresas','editar')) with check (public.tem_permissao('empresas','editar'));

create policy "contas_referenciais_select" on public.contas_referenciais for select to authenticated using (public.tem_permissao('empresas','ver'));
create policy "contas_referenciais_insert" on public.contas_referenciais for insert to authenticated with check (public.tem_permissao('administracao','criar'));

create policy "vinculos_referenciais_select" on public.vinculos_referenciais for select to authenticated using (public.tem_permissao('empresas','ver'));
create policy "vinculos_referenciais_insert" on public.vinculos_referenciais for insert to authenticated with check (public.tem_permissao('empresas','editar'));
