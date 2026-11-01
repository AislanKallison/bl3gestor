// Edge Function: integracao-promotora
//
// Cuida só do provisionamento de usuário (criar/sincronizar admin, gestor,
// corretor ou colaborador + gerar o link de acesso sem senha). Essa é a
// ÚNICA parte que exige privilégio de administrador do Supabase — por isso
// precisa de uma Edge Function. O lançamento de contrato NÃO passa por aqui:
// ele usa a função de banco api_criar_contrato (veja sql/5-api-integracao.sql
// e API-INTEGRACAO.md), que é mais simples de chamar (só SQL/REST, sem
// precisar publicar nada).
//
// Autenticação: header  Authorization: Bearer <chave_da_promotora>
// (a chave vem da tabela api_keys, criada em sql/5-api-integracao.sql)

import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin = createClient(SUPABASE_URL, SERVICE_KEY);

function json(obj: unknown, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function autenticar(req: Request) {
  const auth = req.headers.get("authorization") || "";
  const chave = auth.replace(/^Bearer\s+/i, "").trim();
  if (!chave) return null;
  const { data } = await admin
    .from("api_keys")
    .select("promotora_id, ativa")
    .eq("chave", chave)
    .single();
  if (!data || !data.ativa) return null;
  return data.promotora_id as number;
}

serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  const promotoraId = await autenticar(req);
  if (!promotoraId) return json({ error: "Chave de API inválida ou desativada" }, 401);

  const body = await req.json().catch(() => null);
  const { nome, email, perfil } = body || {};
  if (!nome || !email || !["Admin", "Gestor", "Corretor", "Colaborador"].includes(perfil)) {
    return json({ error: "Informe nome, email e perfil (Admin, Gestor, Corretor ou Colaborador)" }, 400);
  }

  const { data: existentes } = await admin.auth.admin.listUsers();
  let user = existentes?.users?.find((u) => u.email?.toLowerCase() === String(email).toLowerCase());

  if (!user) {
    const { data: created, error: createErr } = await admin.auth.admin.createUser({
      email,
      email_confirm: true,
      user_metadata: { nome },
    });
    if (createErr) return json({ error: createErr.message }, 400);
    user = created.user;

    const { error: profErr } = await admin.from("profiles").insert({
      id: user!.id,
      nome,
      role: perfil,
      promotora_id: perfil === "Admin" ? null : promotoraId,
    });
    if (profErr) return json({ error: "Usuário criado, mas falhou ao salvar perfil: " + profErr.message }, 400);
  }

  // Link de acesso único (expira depois de um tempo) — é com ele que o
  // usuário entra direto no BL3, sem precisar criar/digitar senha.
  const { data: link, error: linkErr } = await admin.auth.admin.generateLink({
    type: "magiclink",
    email,
  });
  if (linkErr) return json({ error: linkErr.message }, 400);

  return json({ ok: true, uid: user!.id, login_url: link.properties?.action_link });
});
