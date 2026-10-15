# Pesquisa e direção — Emberbow

Pesquisa inicial em 12/10/2026. Emberbow é uma implementação independente inspirada no gênero, não uma versão oficial de TowerFall.

## O que foi confirmado

- [Steam oficial](https://store.steampowered.com/app/251470/TowerFall_Ascension/): Ascension é um jogo local para quatro jogadores. Munição limitada, recuperação de flechas e pisões são pilares descritos na página.
- [TowerFall 8-Player oficial](https://maddymakesgamesinc.itch.io/towerfall-8-player): existe uma edição separada para oito jogadores.
- [Anúncios oficiais](https://steamcommunity.com/app/251470/announcements/): documentam captura durante esquiva, extensão da esquiva, regras de torneio, Trigger Arrows e Prism Arrows. Não fornecem uma especificação completa dos tempos de movimento.
- [Towerfall AI](https://github.com/TowerfallAi/towerfall-ai): mod com API de estado, ações de pulo/esquiva/tiro e inventários. Expõe estados de parede, chão, esquiva e diferentes tipos de flecha. Requer o jogo original; não é o código-fonte integral do jogo.
- [TF.EX](https://github.com/Fcornaire/TF.EX): mod em desenvolvimento com FortRise, rollback, salas e replays. É GPL-2.0; nenhum código dele foi copiado aqui. A hipótese de que não existe nenhuma solução online precisa dessa ressalva.
- [Bartizan](https://github.com/Kha/Bartizan): framework de mods, não o código-fonte aberto do TowerFall.
- [Archers](https://github.com/westonkelliher/Archers): referência de jogo de arco em Godot; é top-down e local, portanto não substitui este projeto.
- [Purple vs Yellow](https://richo.itch.io/purple-vs-yellow): candidato a estudo comparativo; fonte/licença e funcionamento não foram auditados nesta etapa.

## Assets

Personagens animados e blocos usam [Dungeon Tileset II, de 0x72](https://0x72.itch.io/dungeontileset-ii); fundos usam [Gothicvania, de Ansimuz](https://opengameart.org/content/gothicvania-patreons-collection). Ambos os pacotes selecionados são CC0. Fontes Cinzel e Atkinson Hyperlegible usam OFL. Créditos e licenças estão em `assets/licenses/`. Áudio sintetizado e efeitos desenhados em código são próprios. Não usamos sprites ou músicas extraídos de TowerFall.

## Mecânicas próprias implementadas

- 60 ticks/s; corrida 245 px/s; gravidade 980 px/s²; pulo 495 px/s.
- Coyote time 100 ms, buffer de pulo 120 ms, pulo variável e salto na parede.
- Dash 160 ms a 570 px/s; recarga 600 ms; captura durante todo o dash.
- Três flechas no início, capacidade seis. Inventário misto preserva o tipo ao coletar ou capturar; R alterna a próxima flecha. Ícones de munição ficam acima do personagem.
- Tiro ao soltar o botão, velocidade 700–748 px/s conforme carga; intervalo 200 ms.
- Um acerto mata. Pisão mata e rebate o atacante.
- Flecha perfurante ignora cenário; flecha detonável explode sob comando do dono (raio 76 px), inclusive podendo atingir o próprio dono.
- Eliminações somam um ponto; autoeliminação subtrai um. Sem bônus por último sobrevivente; esta é a regra solicitada de corrida a dez eliminações, não reprodução exata das variantes oficiais.
- Rodadas terminam com no máximo um vivo; nova rodada após dois segundos.
- Seis arenas com aberturas para wrap horizontal e vertical: sair por uma borda leva à oposta. Névoa fecha as laterais após 40 s.

Todos os números são decisões iniciais do protótipo; não são valores medidos do TowerFall. A fidelidade exige testes lado a lado com uma cópia legítima, gravação de frames e ajuste de movimento/colisões. Não alegamos engenharia reversa binária concluída.

## Rede

[API multiplayer oficial do Godot](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html). ENet/UDP, até quatro participantes, host autoritativo, comandos a 60 Hz, snapshots a 30 Hz. Inputs remotos são limitados e expiram em 300 ms. Cliente envia comandos; host calcula dano e pontuação. Conexões novas são rejeitadas durante a partida.

Há suavização visual dos snapshots. Ainda não há prediction, rollback, lobby público, códigos de convite, relay ou NAT traversal. A resposta no cliente depende da ida e volta de rede. Para internet, o host precisa de IP acessível e porta UDP 24680 encaminhada, ou rede VPN. Um servidor público/relay é necessário para convites sem configuração de roteador. Export web exigiria WebRTC/WebSocket, não ENet.

## Evolução recomendada

1. Playtest de movimento, dash e pisão; revisar câmera fixa, leitura visual e munição.
2. Estado de simulação determinístico separado da apresentação; testes de replay e divergência.
3. Prediction e reconciliação, ou rollback com histórico completo e RNG determinístico. Validar com latência/perda/jitter simulados.
4. Backend de salas e relay, códigos privados e prontidão de todos.
5. Controles remapeáveis, validação física de gamepads, acessibilidade e mixagem.
6. Builds assinadas, exportação multiplataforma e hospedagem após definir plataforma e orçamento.

## Atualização em 14/10/2026

Consulte [OPEN_SOURCE.md](OPEN_SOURCE.md) para a revisão de código aberto. As arenas atuais são desenhadas em código com uma grade compartilhada de colisão; os fundos Gothicvania permanecem no projeto como assets disponíveis. O placar aparece entre rodadas durante 3,4 segundos, incluindo a rodada de vitória. O combate não tem HUD permanente.
