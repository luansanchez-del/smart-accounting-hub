-- Área de staging para integração com o PIER (API v2 real: /arquivos,
-- /solicitacoes, /clientes, /malotedigital, /inteligencia-obrigacoes — sem
-- endpoint de transmissão fiscal). Nada aqui vira lançamento, saldo ou
-- obrigação automaticamente: dados chegam nesta camada, passam por
-- classificação/conferência humana, e só então um passo explícito de
-- "efetivação" (fora desta migration, na camada de aplicação) copia o que
-- foi validado para documentos/saldos_implantacao/lancamentos/obrigacoes.

create table public.pier_importacoes (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  id_cliente_pier int,
  id_solicitacao_pier int,
  competencia text,
  status text not null default 'pendente' check (status in ('pendente','validando','pronto_para_efetivar','efetivado','rejeitado')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index pier_importacoes_empresa_id_idx on public.pier_importacoes (empresa_id);

create table public.pier_arquivos_importados (
  id uuid primary key default gen_random_uuid(),
  pier_importacao_id uuid not null references public.pier_importacoes(id) on delete cascade,
  id_arquivo_pier int not null,
  nome_arquivo text not null,
  categoria text,
  subcategoria text,
  valor numeric(16,2),
  vencimento date,
  competencia text,
  url_download text,
  baixado_em timestamptz,
  created_at timestamptz not null default now()
);

create index pier_arquivos_importados_importacao_id_idx on public.pier_arquivos_importados (pier_importacao_id);

create table public.pier_dados_extraidos (
  id uuid primary key default gen_random_uuid(),
  pier_arquivo_id uuid not null references public.pier_arquivos_importados(id) on delete cascade,
  tipo_documento text,
  dados jsonb not null default '{}'::jsonb,
  confianca numeric(5,2),
  created_at timestamptz not null default now()
);

create table public.pier_pendencias_validacao (
  id uuid primary key default gen_random_uuid(),
  pier_importacao_id uuid not null references public.pier_importacoes(id) on delete cascade,
  descricao text not null,
  resolvida boolean not null default false,
  resolvida_por uuid references auth.users(id),
  resolvida_em timestamptz,
  created_at timestamptz not null default now()
);

alter table public.pier_importacoes enable row level security;
alter table public.pier_arquivos_importados enable row level security;
alter table public.pier_dados_extraidos enable row level security;
alter table public.pier_pendencias_validacao enable row level security;

create policy "pier_importacoes_select" on public.pier_importacoes for select to authenticated using (public.tem_permissao('documentos','ver'));
create policy "pier_importacoes_insert" on public.pier_importacoes for insert to authenticated with check (public.tem_permissao('documentos','criar'));
create policy "pier_importacoes_update" on public.pier_importacoes for update to authenticated using (public.tem_permissao('documentos','editar')) with check (public.tem_permissao('documentos','editar'));

create policy "pier_arquivos_select" on public.pier_arquivos_importados for select to authenticated using (public.tem_permissao('documentos','ver'));
create policy "pier_arquivos_insert" on public.pier_arquivos_importados for insert to authenticated with check (public.tem_permissao('documentos','criar'));

create policy "pier_dados_extraidos_select" on public.pier_dados_extraidos for select to authenticated using (public.tem_permissao('documentos','ver'));
create policy "pier_dados_extraidos_insert" on public.pier_dados_extraidos for insert to authenticated with check (public.tem_permissao('documentos','criar'));

create policy "pier_pendencias_select" on public.pier_pendencias_validacao for select to authenticated using (public.tem_permissao('documentos','ver'));
create policy "pier_pendencias_insert" on public.pier_pendencias_validacao for insert to authenticated with check (public.tem_permissao('documentos','criar'));
create policy "pier_pendencias_update" on public.pier_pendencias_validacao for update to authenticated using (public.tem_permissao('documentos','editar')) with check (public.tem_permissao('documentos','editar'));
