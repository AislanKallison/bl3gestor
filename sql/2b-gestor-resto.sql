-- 2) Convites: substitui o código fixo que ficava visível no código da tela.
--    Cada linha é um convite de uso único (por enquanto, validado por existência).
create table if not exists convites (
  codigo text primary key,
  role user_role not null,
  promotora_id int references promotoras(id),   -- obrigatório quando role = 'Gestor'
  criado_em timestamptz default now()
);
alter table convites enable row level security;
-- ninguém lê a tabela de convites diretamente pelo cliente (só a função abaixo verifica)

create or replace function validar_convite(p_codigo text, p_role user_role, p_promotora_id int default null)
returns boolean as $$
  select exists(
    select 1 from convites
    where codigo = p_codigo and role = p_role
      and (p_role <> 'Gestor' or promotora_id = p_promotora_id)
  );
$$ language sql security definer stable;
grant execute on function validar_convite(text,user_role,int) to anon, authenticated;

-- 3) Funções auxiliares para as novas regras de visibilidade
create or replace function minha_promotora() returns int as $$
  select promotora_id from profiles where id = auth.uid();
$$ language sql security definer stable;

create or replace function is_gestor() returns boolean as $$
  select exists(select 1 from profiles where id = auth.uid() and role = 'Gestor');
$$ language sql security definer stable;

-- 4) Atualiza as permissões: Gestor vê a própria promotora inteira, nunca outra
drop policy if exists "ver_perfis" on profiles;
create policy "ver_perfis" on profiles for select using (
  auth.uid() = id or is_admin() or (is_gestor() and promotora_id = minha_promotora())
);

drop policy if exists "contratos_select" on contratos;
create policy "contratos_select" on contratos for select using (
  is_admin() or vendedor_id = auth.uid()
  or (is_gestor() and vendedor_id in (select id from profiles where promotora_id = minha_promotora()))
);
drop policy if exists "contratos_update" on contratos;
create policy "contratos_update" on contratos for update using (
  is_admin() or vendedor_id = auth.uid()
  or (is_gestor() and vendedor_id in (select id from profiles where promotora_id = minha_promotora()))
);

drop policy if exists "atend_select" on atendimentos;
create policy "atend_select" on atendimentos for select using (
  is_admin() or vendedor_id = auth.uid()
  or (is_gestor() and vendedor_id in (select id from profiles where promotora_id = minha_promotora()))
);
drop policy if exists "atend_update" on atendimentos;
create policy "atend_update" on atendimentos for update using (
  is_admin() or vendedor_id = auth.uid()
  or (is_gestor() and vendedor_id in (select id from profiles where promotora_id = minha_promotora()))
);

-- 5) Crie seu primeiro convite de Admin (troque o código abaixo por um seu, difícil de adivinhar)
insert into convites (codigo, role, promotora_id) values ('TROQUE-ESTE-CODIGO-ADMIN-2026','Admin',null);

-- 6) Exemplo: convite de Gestor para a promotora de id=1 (ajuste o id e o código)
-- insert into convites (codigo, role, promotora_id) values ('CODIGO-DO-SEU-CLIENTE','Gestor',1);
