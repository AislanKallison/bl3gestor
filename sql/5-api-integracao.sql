-- =====================================================================
-- BL3 — API de integração com os sistemas das promotoras
-- Rode isto depois de todos os arquivos anteriores.
-- =====================================================================

-- 1) Uma chave de API por promotora (até 10, ou quantas você quiser)
create table if not exists api_keys (
  id uuid primary key default gen_random_uuid(),
  promotora_id int references promotoras(id) not null,
  chave text not null unique,
  ativa boolean default true,
  criado_em timestamptz default now()
);
alter table api_keys enable row level security;
create policy "api_keys_admin" on api_keys for all using (is_admin()) with check (is_admin());

-- 2) Função que os sistemas das promotoras chamam para ENVIAR UM CONTRATO.
--    O vendedor (Admin ou Corretor) precisa já existir no BL3 — se não existir,
--    a função avisa isso, e o site da promotora deve chamar primeiro a
--    Edge Function "provisionar-usuario" (arquivo separado) para criá-lo.
create or replace function api_criar_contrato(
  p_chave text,
  p_vendedor_email text,
  p_cliente text,
  p_produto text default null,
  p_convenio text default null,
  p_banco text default null,
  p_valor numeric default null,
  p_parcelas int default null,
  p_status text default 'Digitação'
) returns json as $$
declare
  v_promotora int;
  v_vendedor uuid;
  v_novo_id bigint;
begin
  select promotora_id into v_promotora from api_keys where chave = p_chave and ativa = true;
  if v_promotora is null then
    return json_build_object('ok', false, 'erro', 'chave de API inválida ou inativa');
  end if;

  if p_cliente is null or length(trim(p_cliente)) < 3 or p_valor is null or p_valor < 500 or p_parcelas is null or p_parcelas < 1 then
    return json_build_object('ok', false, 'erro', 'dados obrigatórios ausentes ou inválidos (cliente, valor, parcelas)');
  end if;

  select p.id into v_vendedor
    from profiles p join auth.users u on u.id = p.id
   where lower(u.email) = lower(p_vendedor_email) and p.promotora_id = v_promotora;

  if v_vendedor is null then
    return json_build_object('ok', false, 'erro', 'vendedor não cadastrado nesta promotora', 'precisa_provisionar', true);
  end if;

  insert into contratos (cliente, vendedor_id, produto, convenio, banco, valor, parcelas, status)
  values (trim(p_cliente), v_vendedor, p_produto, p_convenio, p_banco, p_valor, p_parcelas, coalesce(p_status, 'Digitação'))
  returning id into v_novo_id;

  return json_build_object('ok', true, 'contrato_id', v_novo_id);
end;
$$ language plpgsql security definer;

grant execute on function api_criar_contrato(text,text,text,text,text,text,numeric,int,text) to anon, authenticated;

-- 3) Função auxiliar que a Edge Function de provisionamento usa para validar a chave
create or replace function api_validar_chave(p_chave text) returns int as $$
  select promotora_id from api_keys where chave = p_chave and ativa = true;
$$ language sql security definer stable;
grant execute on function api_validar_chave(text) to anon, authenticated, service_role;
