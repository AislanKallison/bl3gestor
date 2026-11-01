# API de integração BL3 Gestão

Esta API permite que o sistema da sua promotora cadastre vendedores e envie
contratos direto no BL3, sem precisar de importação manual. São dois
mecanismos diferentes — use o que for pedido em cada seção.

**Autenticação dos dois:** uma chave de API por promotora, fornecida pela BL3
(gerada em `sql/5-api-integracao.sql`). Não compartilhe.

---

## 1) Cadastrar ou sincronizar um vendedor (Admin, Gestor, Corretor, Colaborador)

Chame isso sempre que um usuário novo for criado no seu sistema. Se o e-mail
já existir no BL3, nada é duplicado.

**Endereço:** `https://ctmwsxvkdrffvdbaxlwj.supabase.co/functions/v1/integracao-promotora`
**Método:** `POST`
**Cabeçalho:** `Authorization: Bearer <sua chave de API>`

```json
{
  "nome": "Maria Vendedora",
  "email": "maria@suapromotora.com.br",
  "perfil": "Corretor"
}
```

`perfil` aceita: `Admin`, `Gestor`, `Corretor` ou `Colaborador`.

**Resposta de sucesso:**
```json
{ "ok": true, "uid": "uuid-do-usuario", "login_url": "https://...link-de-acesso-unico" }
```

O `login_url` é o link para esse usuário entrar direto no BL3, sem precisar
criar senha. Exiba-o (ou redirecione automaticamente) na tela do seu sistema.
Esse link expira depois de um tempo — gere um novo a cada vez que o usuário
for acessar.

---

## 2) Lançar um contrato

O vendedor (`vendedor_email`) precisa já existir no BL3 — chame a ação
acima primeiro, se ainda não tiver feito.

**Endereço:** `https://ctmwsxvkdrffvdbaxlwj.supabase.co/rest/v1/rpc/api_criar_contrato`
**Método:** `POST`
**Cabeçalhos:**
- `apikey: <chave pública anon do projeto, fornecida pela BL3>`
- `Content-Type: application/json`

```json
{
  "p_chave": "<sua chave de API>",
  "p_vendedor_email": "maria@suapromotora.com.br",
  "p_cliente": "José da Silva",
  "p_produto": "Novo contrato",
  "p_convenio": "INSS",
  "p_banco": "Banco Alfa",
  "p_valor": 8500,
  "p_parcelas": 60,
  "p_status": "Digitação"
}
```

**Resposta de sucesso:**
```json
{ "ok": true, "contrato_id": 1234 }
```

**Resposta de erro** (sempre com `"ok": false`, nunca um código HTTP de erro,
já que é uma função de banco):
```json
{ "ok": false, "erro": "vendedor não cadastrado nesta promotora", "precisa_provisionar": true }
```

---

## Por que são dois mecanismos diferentes

Cadastrar um contrato é uma operação simples de banco de dados — por isso
usa só uma função SQL, mais rápida de configurar. Já criar um usuário de
login exige privilégio de administrador do sistema (algo que, por segurança,
não pode rodar direto no banco) — por isso essa parte precisa de uma Edge
Function publicada à parte. Do ponto de vista de quem está integrando, a
diferença é só o endereço chamado; o formato de autenticação é o mesmo.
