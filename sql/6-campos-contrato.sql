-- =====================================================================
-- BL3 — Novos campos no contrato (CPF, data de nascimento, telefone,
-- matrícula/benefício, data de averbação). Seguro de rodar com dados já
-- existentes: as colunas entram vazias (null) nos contratos antigos.
-- =====================================================================
alter table contratos
  add column if not exists cpf text,
  add column if not exists data_nascimento date,
  add column if not exists telefone text,
  add column if not exists matricula text,
  add column if not exists data_averbacao date,
  add column if not exists observacoes text,
  add column if not exists tabela text,
  add column if not exists valor_liquido numeric(12,2),
  add column if not exists fisico text default '-',
  add column if not exists status_comissao text default 'AG. CR Cliente';

-- Alinha o vocabulário de status com o que já é usado na operação real.
-- Atenção: isso RENOMEIA os valores de status já gravados em contratos
-- existentes. Rode só depois de confirmar que faz sentido para você.
update contratos set status='Analise Banco' where status in ('Digitação','Análise');
update contratos set status='Concretizado' where status in ('Averbado','Pago');
update contratos set status='CR Cliente' where status='Aprovado';
update contratos set status='Pendente' where status='Pendência';
-- 'Cancelado' já tem o mesmo nome nos dois vocabulários, não precisa trocar.
