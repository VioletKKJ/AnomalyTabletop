# Anomaly VTT

Uma mesa virtual de RPG (VTT) feita para jogar com amigos, diretamente pelo navegador. O projeto é pessoal e prioriza praticidade para sessões presenciais ou online em pequenos grupos.

O frontend é uma página estática (\`index.html\`) hospedada pelo GitHub Pages. Banco de dados, autenticação própria, armazenamento de imagens e sincronização em tempo real são fornecidos pelo Supabase.

## Funcionalidades

### Mesa e cenas
- Criação de mesas, entrada por código e gerenciamento de participantes.
- Papéis de mestre e jogador, com ferramentas exclusivas para o mestre.
- Várias cenas por mesa, cada uma com seu próprio mapa e elementos.
- Troca de cena sincronizada entre os participantes.
- Exclusão de mesas e cenas com etapas de confirmação.

### Mapas e tokens
- Importação de mapas, imagens e peças de cenário.
- Tokens personalizados com suporte a estados/variações de imagem.
- Mover, redimensionar, girar, espelhar e organizar tokens em camadas.
- Seleção múltipla e movimentação conjunta de tokens.
- Propriedades de token: nome, cor, opacidade, visibilidade, bloqueio e outras configurações.
- Ocultar tokens e nomes dos jogadores.
- Biblioteca para guardar e organizar tokens e recursos reutilizáveis.

### Ferramentas de mapa
- Grid configurável e ajuste de escala.
- Névoa de guerra, incluindo ferramentas de edição.
- Paredes e portas para delimitar áreas.
- Iluminação e configurações de visão dos tokens.
- Ferramenta de desenho com opções de cor e espessura, além de desfazer.
- Régua para medir distâncias no mapa.
- Elementos de ambiente: horário, clima, tonalidade e efeitos visuais.

### Câmera e apresentação
- Zoom e movimentação livre da câmera.
- Modos de seleção e movimentação da câmera.
- Opções para centralizar a câmera dos jogadores e acompanhar a câmera do mestre.
- Modo de projetor para exibir a mesa em outra tela.
- Interface com barras e painéis recolhíveis, adaptada para computador, celular e tablet.

### Comunicação e dados
- Chat da mesa com mensagens sincronizadas.
- Rolagem de dados com expressões e resultados exibidos no tabuleiro.
- Itens compartilhados pelo mestre com todos os jogadores ou com uma pessoa específica.
- Visualizador 2.5D para examinar imagens com rotação, inclinação, zoom, perspectiva, sombra e brilho.
- Espelhamento da inspeção de itens no modo projetor.

## Tecnologias e arquitetura

- **Frontend:** HTML, CSS e JavaScript em uma página única (\`index.html\`).
- **Hospedagem:** GitHub Pages.
- **Banco de dados:** PostgreSQL pelo Supabase.
- **Sincronização:** Supabase Realtime para propagar alterações entre participantes.
- **Arquivos:** Supabase Storage para imagens e recursos enviados.
- **Operações protegidas:** funções RPC no banco para ações que exigem validação de permissões.
- **Acesso:** sistema próprio de cadastro e login, separado do Supabase Auth.

As credenciais de conexão do Supabase são informadas na primeira configuração e ficam salvas no armazenamento local do navegador para permitir a reconexão automática naquele dispositivo. Cada participante precisa configurar a conexão e entrar com sua própria conta.

## Estrutura do repositório

- \`index.html\`: aplicação completa, incluindo interface, estilos e lógica do frontend.
- \`SQL/schema_snapshot.sql\`: snapshot da estrutura do banco conectado, incluindo tabelas, funções, índices e políticas. Não contém os dados das mesas ou dos usuários.
- \`SQL/shared_items.sql\`: criação da tabela e das RPCs do sistema de itens compartilhados.
- \`SQL/\` e \`supabase/sql/\`: scripts SQL de alterações e funções específicas do banco.

### Sobre o snapshot SQL

O arquivo \`SQL/schema_snapshot.sql\` serve como documentação e referência do estado do banco no momento em que foi capturado. **Não execute esse snapshot cegamente em um banco existente.** Ele pode conflitar com objetos já criados e não substitui um processo de migração planejado.

Os scripts SQL individuais devem ser lidos e aplicados somente quando a alteração correspondente for necessária. As políticas de RLS existentes são intencionais e fazem parte do modelo de permissões do projeto.

## Executar e publicar

### 1. Configurar o Supabase

O projeto precisa de uma instância Supabase própria. Na configuração da aplicação, informe:

- **Project URL**
- **Anon public key**

Esses valores podem ser encontrados nas configurações de API do projeto Supabase. A chave pública anon é destinada ao uso no frontend; nunca coloque uma chave \`service_role\` no \`index.html\` ou em qualquer arquivo público.

O banco também precisa conter o schema, as funções RPC, as políticas RLS e os buckets de Storage esperados pela versão atual da aplicação. Para reproduzir o ambiente, consulte os arquivos SQL do repositório e compare-os com o estado real do projeto antes de aplicar qualquer script.

### 2. Publicar pelo GitHub Pages

1. Abra as configurações do repositório no GitHub.
2. Em **Pages**, configure a publicação pela branch \`main\` e pela pasta raiz.
3. Salve e aguarde a publicação.
4. Acesse o endereço fornecido pelo GitHub Pages.

O arquivo de entrada já se chama \`index.html\`, portanto não é necessário renomear arquivos. Atualizações publicadas na branch principal serão disponibilizadas pelo GitHub Pages após o processamento.

### 3. Entrar na mesa

1. Abra o endereço publicado.
2. Informe a URL e a anon public key do Supabase, caso seja o primeiro acesso naquele navegador.
3. Crie uma conta ou entre com uma conta existente.
4. Crie uma mesa ou entre em uma mesa usando o código de acesso.
5. Compartilhe o código da mesa com os demais participantes.

## Observações e limitações conhecidas

- O projeto é desenvolvido para uso pessoal com um grupo pequeno de amigos, não como um serviço público multiusuário.
- A aplicação depende de conexão com a internet e da disponibilidade do Supabase.
- Os canais Realtime contam com monitoramento e tentativa de reconexão automática. Se uma falha persistir, ainda pode ser necessário atualizar a página.
- O uso do plano gratuito do Supabase está sujeito aos limites e às regras vigentes da plataforma, que podem mudar.
- Não compartilhe credenciais privadas nem coloque chaves administrativas no repositório.

## Direção do projeto

A prioridade é manter as ferramentas existentes estáveis e úteis durante as sessões. Novas funcionalidades devem ser adicionadas com cuidado para não comprometer os recursos já utilizados.

---

Projeto pessoal de VTT para campanhas de RPG entre amigos.
