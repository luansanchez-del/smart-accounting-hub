-- Fundação de autenticação e permissões do ERP V2.
-- Permissões são concedidas por CAPACIDADE (empresas, documentos, lancamentos,
-- conciliacao, obrigacoes, fechamento, relatorios, inteligencia, administracao),
-- não por regime tributário — o regime é um atributo da empresa, não do usuário.

create table public.funcoes (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  descricao text not null default '',
  permissoes jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null default '',
  email text not null default '',
  funcao_id uuid references public.funcoes(id),
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.funcoes enable row level security;
alter table public.profiles enable row level security;

create policy "funcoes_select_authenticated" on public.funcoes
  for select to authenticated using (true);

create or replace function public.tem_permissao(p_modulo text, p_acao text)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles pr
    join public.funcoes f on f.id = pr.funcao_id
    join jsonb_array_elements(f.permissoes) perm on true
    where pr.id = auth.uid()
      and pr.ativo
      and perm->>'modulo' = p_modulo
      and perm->'acoes' ? p_acao
  );
$$;

create policy "profiles_select_self_or_admin" on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.tem_permissao('administracao', 'ver'));

-- Cria automaticamente uma linha em profiles quando um usuário se cadastra.
-- Sem funcao_id (sem permissão nenhuma) até um Administrador atribuir uma função.
create or replace function public.lidar_novo_usuario()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, nome, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome', ''), new.email);
  return new;
end;
$$;

create trigger ao_criar_usuario
  after insert on auth.users
  for each row execute function public.lidar_novo_usuario();

create or replace function public.tocar_auditoria()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  new.updated_by = auth.uid();
  return new;
end;
$$;

-- Seed: 3 funções base. Ajustar/expandir depois pela tela de Administração.
insert into public.funcoes (nome, descricao, permissoes) values
('Administrador', 'Acesso completo ao sistema', '[
  {"modulo":"empresas","acoes":["ver","criar","editar","excluir"]},
  {"modulo":"documentos","acoes":["ver","criar","editar","excluir"]},
  {"modulo":"lancamentos","acoes":["ver","criar","editar","efetivar"]},
  {"modulo":"conciliacao","acoes":["ver","criar","editar"]},
  {"modulo":"obrigacoes","acoes":["ver","criar","editar","excluir"]},
  {"modulo":"fechamento","acoes":["ver","criar","editar","efetivar"]},
  {"modulo":"relatorios","acoes":["ver"]},
  {"modulo":"inteligencia","acoes":["ver"]},
  {"modulo":"administracao","acoes":["ver","criar","editar","excluir"]}
]'::jsonb),
('Contador', 'Executa a rotina contábil das empresas sob sua carteira', '[
  {"modulo":"empresas","acoes":["ver","criar","editar"]},
  {"modulo":"documentos","acoes":["ver","criar","editar"]},
  {"modulo":"lancamentos","acoes":["ver","criar","editar"]},
  {"modulo":"conciliacao","acoes":["ver","criar","editar"]},
  {"modulo":"obrigacoes","acoes":["ver","criar","editar"]},
  {"modulo":"fechamento","acoes":["ver","criar"]},
  {"modulo":"relatorios","acoes":["ver"]},
  {"modulo":"inteligencia","acoes":["ver"]}
]'::jsonb),
('Consulta', 'Somente leitura', '[
  {"modulo":"empresas","acoes":["ver"]},
  {"modulo":"documentos","acoes":["ver"]},
  {"modulo":"lancamentos","acoes":["ver"]},
  {"modulo":"conciliacao","acoes":["ver"]},
  {"modulo":"obrigacoes","acoes":["ver"]},
  {"modulo":"fechamento","acoes":["ver"]},
  {"modulo":"relatorios","acoes":["ver"]},
  {"modulo":"inteligencia","acoes":["ver"]}
]'::jsonb);
