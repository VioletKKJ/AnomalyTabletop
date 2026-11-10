# Atenção
Esse projeto está sendo feito utilizando o claude, é puramente vibecoded, é só um TTS simples para jogar com uns amigos.


# Tabletop Web

Um tabletop virtual (VTT) simples, gratuito e sem servidor próprio — feito para mesas de RPG entre amigos. Funciona no PC, celular e tablet, e sincroniza mapa e tokens em tempo real entre todos os jogadores usando o [Supabase](https://supabase.com) (plano gratuito).

Não é um produto público: é um projeto pessoal, feito pra rodar com uma conta Supabase gratuita de um grupo de amigos.

## Funcionalidades

- **Mapas e tokens customizados**: importe qualquer PNG/JPG para usar como mapa ou token.
- **Sincronização em tempo real**: tudo que o mestre ou os jogadores fazem aparece na hora para todo mundo.
- **Contas simples**: login só com usuário e senha (sem e-mail). Quem entra primeiro numa mesa nova pode virar mestre; o mestre pode promover/trocar quem é mestre depois.
- **Cenas**: cada cena guarda seu próprio mapa e seus próprios tokens. Trocar de cena (ex. "Padaria" → "Cidade") troca os dois juntos, instantaneamente.
- **Tokens**: arrastar, redimensionar, girar, espelhar, trocar de camada (na frente/atrás de outros tokens) e trocar entre "estados" (variações de imagem do mesmo token — ex. de pé / caído).
- **Menu de contexto**: botão direito (PC) ou toque longo (celular/tablet) no token abre um menu rápido com essas ações.
- **Ferramentas de câmera**: modo "Selecionar" (move tokens, ainda navega a câmera) e modo "Mover" (só navega, não mexe em tokens) — pensado pra não esbarrar em tokens sem querer no toque.
- **Zoom livre** (0.05x–10x) e pan com 1 dedo, pinça com 2 dedos no toque.
- **Interface com barras colapsáveis**, pra sobrar mais espaço de mapa no celular.

## Como funciona (arquitetura)

Não existe servidor próprio: o arquivo `tabletop-supabase.html` é uma página única (HTML + CSS + JavaScript) que fala direto com o Supabase pela internet.

- **Banco de dados (Postgres)**: guarda contas, cenas, mapas e tokens.
- **Realtime**: avisa todo mundo conectado assim que algo muda.
- **Storage**: guarda as imagens de mapas e tokens.
- **Funções RPC**: toda ação que precisa de permissão (trocar mapa, criar/apagar token, trocar de mestre etc.) passa por funções no próprio banco, que checam quem está pedindo antes de fazer qualquer coisa — mesmo alguém mexendo direto na API não consegue burlar as regras.
- **Login próprio**: não usa o sistema de contas do Supabase (Auth) — usuário e senha ficam em tabelas próprias, com a senha protegida por hash (`pgcrypto`).

Hospedar o `tabletop-supabase.html` no GitHub Pages é opcional — o arquivo funciona igual se aberto direto do computador, já que toda a "inteligência" mora no Supabase.

## Como colocar no ar

### 1. Criar o projeto no Supabase
1. Crie uma conta grátis em [supabase.com](https://supabase.com) (sem cartão) e um novo projeto.
2. Em **Project Settings → API**, anote o **Project URL** e a **anon public key**.

### 2. Rodar o script de banco de dados
1. Abra o **SQL Editor** do projeto.
2. Cole o conteúdo de `tabletop-supabase-setup.sql` inteiro e rode (▶ Run).
   - O script é seguro de rodar mais de uma vez (usa `if not exists`/`or replace` em tudo).
3. Em **Database → Extensions**, confirme que `pgcrypto` está ativado (o script já tenta ativar sozinho, mas vale conferir).

### 3. Abrir o app
1. Abra `tabletop-supabase.html` num navegador (local ou publicado — ver abaixo).
2. Na primeira vez, cole a **Project URL** e a **anon public key** do passo 1.
3. Crie sua conta (usuário + senha) e clique em **"👑 Virar mestre desta mesa"**.
4. Mande o link/arquivo pros seus amigos — cada um cria a própria conta e já entra como jogador.

### 4. (Opcional) Publicar no GitHub Pages
1. Crie um repositório novo no GitHub (pode ser público — o arquivo não contém nenhuma senha ou chave fixa).
2. Suba o `tabletop-supabase.html` renomeado para `index.html`.
3. Em **Settings → Pages**, ative o GitHub Pages (branch `main`, pasta raiz).
4. O link fica fixo no formato `https://seu-usuario.github.io/repositorio/`.

> Atualizações: toda vez que eu te mandar um `tabletop-supabase.html` novo, é só subir ele de novo com o mesmo nome (`index.html`) pra substituir — o link continua o mesmo.

## Estrutura do banco (resumo)

| Tabela | O que guarda |
|---|---|
| `auth_users` | Usuário e senha (hash). Nunca exposta pela API — só por dentro das funções de login. |
| `profiles` | Nome e papel (mestre/jogador) de cada conta. |
| `scenes` | Cada cena salva: nome e imagem do mapa. |
| `board` | Estado atual da mesa: qual cena está ativa. |
| `tokens` | Cada token: imagem, posição, tamanho, rotação, camada, estados etc. — todos ligados a uma cena. |

Toda escrita de verdade acontece por **funções RPC** (`login_user`, `signup_user`, `set_map`, `add_token`, `move_token`, `set_scene`, `set_role` etc.), nunca direto nas tabelas.

## Limitações conhecidas (plano gratuito do Supabase)

- ~500 MB de banco, ~1 GB de armazenamento de imagens, ~10 GB de banda por mês — bem confortável pra um grupo de amigos, mesmo numa sessão de um dia inteiro.
- O projeto Supabase **pausa sozinho** depois de ~7 dias sem uso (não perde dados, só precisa reativar no painel antes da próxima sessão).

## Roadmap / próximas ideias

- [x] Editor para recortar a imagem do token (hitbox, hoje é a imagem inteira)
- [ ] Grid e fog of war (névoa de guerra)
- [ ] Mais ferramentas na barra lateral (régua/medição, desenho)
- [ ] Opção de escala do mapa / múltiplos mapas lado a lado
- [x] Tema visual (cinza + roxo)
- [ ] Dados (rolagem)

## Aviso

Este é um projeto pessoal/hobby, pensado pra um grupo pequeno de amigos. As regras de permissão protegem contra erros e uso casual, mas o modelo de segurança não foi feito pra resistir a um usuário mal-intencionado com conhecimento técnico — não é recomendado pra mesas com desconhecidos.
