-- Matriz de obrigações acessórias. O fluxo de status reflete o pipeline
-- descrito na arquitetura: prevista -> ... -> pagamento_conciliado.
-- Transmissão automática NÃO é assumida aqui — "transmitida" e
-- "recibo_validado" exigem evidência/recibo real anexado via documentos,
-- nunca são marcados automaticamente pelo sistema.

create table public.obrigacoes (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  competencia_id uuid not null references public.competencias(id) on delete cascade,
  tipo text not null,
  esfera text not null check (esfera in ('federal','estadual','municipal','trabalhista','contabil')),
  vencimento_legal date not null,
  vencimento_ajustado date,
  responsavel_id uuid references auth.users(id),
  status text not null default 'prevista' check (status in (
    'prevista','aguardando_documentos','em_apuracao','aguardando_revisao',
    'pronta_para_transmissao','transmitida','recibo_validado','guia_emitida','pagamento_conciliado'
  )),
  recibo_documento_id uuid references public.documentos(id),
  guia_documento_id uuid references public.documentos(id),
  observacoes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

create index obrigacoes_empresa_id_idx on public.obrigacoes (empresa_id);
create index obrigacoes_competencia_id_idx on public.obrigacoes (competencia_id);
create index obrigacoes_vencimento_legal_idx on public.obrigacoes (vencimento_legal);

alter table public.obrigacoes enable row level security;

create policy "obrigacoes_select" on public.obrigacoes for select to authenticated using (public.tem_permissao('obrigacoes','ver'));
create policy "obrigacoes_insert" on public.obrigacoes for insert to authenticated with check (public.tem_permissao('obrigacoes','criar') and created_by = auth.uid());
create policy "obrigacoes_update" on public.obrigacoes for update to authenticated using (public.tem_permissao('obrigacoes','editar')) with check (public.tem_permissao('obrigacoes','editar'));
create policy "obrigacoes_delete" on public.obrigacoes for delete to authenticated using (public.tem_permissao('obrigacoes','excluir'));

create trigger obrigacoes_auditoria before update on public.obrigacoes for each row execute function public.tocar_auditoria();
