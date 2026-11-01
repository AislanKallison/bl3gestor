# BL3 Gestão — pacote completo

```
bl3-gestao-completo/
├── site/                 ← ISTO vai para a Hostinger
│   ├── index.html        (sistema inteiro: HTML + CSS + JS num arquivo só)
│   └── .htaccess         (redireciona para HTTPS)
├── sql/                  ← scripts do banco (Supabase), na ordem abaixo
├── supabase/functions/   ← Edge Function da API de integração (opcional)
├── docs/API-INTEGRACAO.md
└── modelos/BL3-modelo-importacao-pronto.xlsx
```

## Testar no VSCode
1. Arquivo → Abrir Pasta → escolha `bl3-gestao-completo`
2. Botão direito em `site/index.html` → **Open with Live Server**
3. Supabase → Authentication → URL Configuration → adicione o endereço que abrir
   (ex.: http://127.0.0.1:5500) em Redirect URLs.

## Subir na Hostinger
1. hPanel → Sites → seu domínio → **Gerenciador de Arquivos** → pasta `public_html`.
2. Envie **o conteúdo da pasta `site/`** (index.html e .htaccess) para dentro de `public_html`
   (não envie a pasta `site` em si, nem as pastas `sql` e `supabase`).
3. hPanel → **SSL**: ative o certificado gratuito do domínio (necessário para HTTPS).
4. Supabase → Authentication → URL Configuration:
   - **Site URL**: https://seudominio.com.br
   - **Redirect URLs**: adicione https://seudominio.com.br e https://seudominio.com.br/index.html
5. Se usar login com Google: Google Cloud Console → Credenciais → seu Client ID →
   "Origens JavaScript autorizadas": adicione https://seudominio.com.br
   (o URI de redirecionamento continua sendo o do Supabase, `.../auth/v1/callback`).
6. Teste cadastro, login e importação já no domínio.

## Ordem dos scripts SQL (só se for recriar o banco do zero)
1-schema-base → 2a-enum-gestor (rode SOZINHO) → 2b-gestor-resto → 3-dados-reais →
4-nomes-promotoras → 5-api-integracao → 6-campos-contrato.
Se o seu Supabase atual já está funcionando, NÃO precisa rodar nada de novo.
(Atenção: o 6 também renomeia status de contratos existentes.)

## Antes de dar o endereço a clientes
- `EXIGIR_CONVITE` está **false** no início do script dentro de `site/index.html`
  (busque por `EXIGIR_CONVITE`). Troque para `true` para que só quem tem convite
  crie conta de Admin/Gestor. Crie os convites na tabela `convites` do Supabase.
- Use o plano Supabase Pro (o gratuito pausa por inatividade e não faz backup).
- As chaves SUPABASE_URL e SUPABASE_ANON_KEY ficam no início do script (a chave anon é pública
  por desenho; a proteção é feita pelas regras RLS do banco). NUNCA coloque a chave service_role no site.

## Importação de contratos (Esteira → Importar Excel)
Veja `modelos/BL3-modelo-importacao-pronto.xlsx` (aba Instruções). Aceita também relatórios
no formato WorkBank (cabeçalhos em maiúsculas, linha de título antes do cabeçalho).
O vendedor/agente da planilha precisa já ter conta; com Vendedor vazio, o contrato entra
no nome de quem importa (Gestor, Corretor ou Colaborador).

## Redefinição de senha (se o e-mail não chegar ou o link não funcionar)
1. Supabase → Authentication → URL Configuration: o endereço que você está usando
   (ex.: http://127.0.0.1:5500/index.html ou https://seudominio.com.br/index.html)
   precisa estar em **Redirect URLs**. Sem isso, o link abre outra página.
2. O Supabase gratuito envia poucos e-mails por hora. Se aparecer "Muitos pedidos seguidos", espere.
   Confira também o spam. Para uso comercial, configure um SMTP próprio em
   Authentication → Emails → SMTP Settings.
3. Abra o link no MESMO navegador onde pediu. O link expira rápido e só vale uma vez.
