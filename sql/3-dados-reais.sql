-- =====================================================================
-- BL3 — Ajustes para a esteira de contratos usar dados reais
-- Rode isto DEPOIS dos dois arquivos SQL anteriores.
-- =====================================================================

-- 1) A lista de promotoras precisa ser lida ANTES do login (tela de cadastro
--    mostra o nome real da promotora no lugar dos nomes de demonstração)
drop policy if exists "promotoras_select" on promotoras;
create policy "promotoras_select" on promotoras for select using (true);

-- 2) O Gestor também precisa poder CRIAR contrato em nome de qualquer
--    vendedor da própria promotora (não só o Admin e o próprio vendedor)
drop policy if exists "contratos_insert" on contratos;
create policy "contratos_insert" on contratos for insert with check (
  is_admin() or vendedor_id = auth.uid()
  or (is_gestor() and vendedor_id in (select id from profiles where promotora_id = minha_promotora()))
);
