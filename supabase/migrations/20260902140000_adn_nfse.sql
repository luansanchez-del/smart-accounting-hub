-- Coleta de NFS-e no Ambiente de Dados Nacional (ADN) por NSU.
-- O certificado digital nunca é persistido no banco: ele é fornecido à
-- Edge Function exclusivamente por Secrets do projeto.

alter table public.documentos drop constraint if exists documentos_origem_check;
alter table public.documentos
  add constraint documentos_origem_check
  check (origem in ('upload', 'pier', 'adn_nfse', 'importacao', 'manual'));

create table public.adn_nfse_configuracoes (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null unique references public.empresas(id) on delete cascade,
  ambiente text not null default 'producao_restrita'
    check (ambiente in ('producao', 'producao_restrita')),
  cnpj_consulta text not null check (cnpj_consulta ~ '^[0-9A-Z]{14}$'),
  ultimo_nsu bigint not null default 0 check (ultimo_nsu >= 0),
  ativa boolean not null default false,
  ultima_execucao_em timestamptz,
  ultimo_sucesso_em timestamptz,
  ultimo_erro text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.adn_nfse_documentos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  documento_id uuid not null references public.documentos(id) on delete cascade,
  nsu bigint not null check (nsu >= 0),
  chave_acesso text not null default '',
  tipo_documento text not null,
  tipo_evento text,
  data_geracao timestamptz,
  xml text not null,
  hash_sha256 text not null,
  created_at timestamptz not null default now(),
  unique (empresa_id, nsu),
  unique (empresa_id, hash_sha256)
);

create index adn_nfse_documentos_empresa_id_idx
  on public.adn_nfse_documentos (empresa_id);
create index adn_nfse_documentos_chave_acesso_idx
  on public.adn_nfse_documentos (chave_acesso)
  where chave_acesso <> '';

alter table public.adn_nfse_configuracoes enable row level security;
alter table public.adn_nfse_documentos enable row level security;

create policy "adn_nfse_configuracoes_select"
  on public.adn_nfse_configuracoes for select to authenticated
  using (public.tem_permissao('documentos', 'ver'));
create policy "adn_nfse_configuracoes_insert"
  on public.adn_nfse_configuracoes for insert to authenticated
  with check (public.tem_permissao('documentos', 'criar'));
create policy "adn_nfse_configuracoes_update"
  on public.adn_nfse_configuracoes for update to authenticated
  using (public.tem_permissao('documentos', 'editar'))
  with check (public.tem_permissao('documentos', 'editar'));

create policy "adn_nfse_documentos_select"
  on public.adn_nfse_documentos for select to authenticated
  using (public.tem_permissao('documentos', 'ver'));

comment on table public.adn_nfse_configuracoes is
  'Parâmetros e cursor da coleta de NFS-e no ADN por empresa.';
comment on column public.adn_nfse_configuracoes.cnpj_consulta is
  'CNPJ alfanumérico, sem pontuação; deve possuir a mesma raiz do certificado.';
comment on table public.adn_nfse_documentos is
  'XMLs brutos coletados no ADN; imutáveis e deduplicados por NSU e SHA-256.';
