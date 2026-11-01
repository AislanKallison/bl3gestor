-- =====================================================================
-- BL3 Gestão — Schema para Supabase (Postgres)
-- Cole este arquivo inteiro no SQL Editor do seu projeto Supabase e rode.
-- =====================================================================

create type user_role as enum ('Admin','Corretor','Colaborador');

-- Promotoras cadastradas pela financeira
create table promotoras (
  id serial primary key,
  nome text not null
);
insert into promotoras (nome) values
 ('Alfa Promotora'),('Norte Crédito'),('Litoral Consig'),('Sertão Correspondente');

-- Perfil de cada usuário (1 linha por conta de login)
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null,
  role user_role not null default 'Colaborador',
  promotora_id int references promotoras(id),
  plano text default 'basic',              -- 'basic' (R$200) ou 'ia' (R$300), usado por promotora
  criado_em timestamptz default now()
);

-- Contratos da esteira
create table contratos (
  id bigserial primary key,
  cliente text not null,
  vendedor_id uuid references profiles(id),
  produto text,
  convenio text,
  banco text,
  valor numeric(12,2) not null,
  parcelas int not null,
  status text not null default 'Digitação',
  motivo_pendencia text,
  criado_em timestamptz default now()
);

-- Fila de atendimento
create table atendimentos (
  id bigserial primary key,
  cliente text,
  canal text,
  assunto text,
  atendido_por_ia boolean default false,
  vendedor_id uuid references profiles(id),
  status text not null default 'Aguardando',
  criado_em timestamptz default now()
);

-- Log de auditoria
create table auditoria (
  id bigserial primary key,
  usuario_id uuid references profiles(id),
  acao text not null,
  detalhe text,
  criado_em timestamptz default now()
);

-- Configuração de integração de IA (Hermes / DeepSeek) — só o Admin lê/edita
create table integracoes (
  id int primary key default 1,
  hermes_webhook text,
  deepseek_key text,
  check (id = 1)
);
insert into integracoes (id) values (1);

-- =====================================================================
-- ROW LEVEL SECURITY — cada perfil só vê o que pode ver, garantido pelo banco
-- =====================================================================
alter table profiles enable row level security;
alter table contratos enable row level security;
alter table atendimentos enable row level security;
alter table auditoria enable row level security;
alter table integracoes enable row level security;

-- função auxiliar: o usuário logado é Admin?
create or replace function is_admin() returns boolean as $$
  select exists(select 1 from profiles where id = auth.uid() and role = 'Admin');
$$ language sql security definer stable;

-- profiles
create policy "ver_perfis" on profiles for select using (auth.uid() = id or is_admin());
create policy "criar_proprio_perfil" on profiles for insert with check (auth.uid() = id);
create policy "atualizar_perfil" on profiles for update using (auth.uid() = id or is_admin());

-- contratos: Admin vê tudo; vendedor vê e edita só os próprios
create policy "contratos_select" on contratos for select using (is_admin() or vendedor_id = auth.uid());
create policy "contratos_insert" on contratos for insert with check (is_admin() or vendedor_id = auth.uid());
create policy "contratos_update" on contratos for update using (is_admin() or vendedor_id = auth.uid());

-- atendimentos: mesma regra dos contratos
create policy "atend_select" on atendimentos for select using (is_admin() or vendedor_id = auth.uid());
create policy "atend_insert" on atendimentos for insert with check (auth.uid() is not null);
create policy "atend_update" on atendimentos for update using (is_admin() or vendedor_id = auth.uid());

-- auditoria: todo usuário logado pode registrar; só o Admin lê o histórico completo
create policy "auditoria_insert" on auditoria for insert with check (auth.uid() is not null);
create policy "auditoria_select" on auditoria for select using (is_admin());

-- promotoras: qualquer usuário logado pode ler a lista (para preencher o cadastro)
alter table promotoras enable row level security;
create policy "promotoras_select" on promotoras for select using (auth.uid() is not null);

-- integrações: só o Admin lê e edita
create policy "integ_select" on integracoes for select using (is_admin());
create policy "integ_update" on integracoes for update using (is_admin());
