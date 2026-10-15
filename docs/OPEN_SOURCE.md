# Referências de mecânicas — 14/10/2026

## Controlador Godot reutilizável

[markolainen/platformer-character-controller](https://github.com/markolainen/platformer-character-controller) — Godot 3.5.1, [CC0-1.0](https://github.com/markolainen/platformer-character-controller/blob/main/LICENSE).

O arquivo Player.gd implementa dash, pulo variável, buffer, tolerância após sair da plataforma e correção de quinas. Foi lido como referência técnica. `scripts/player.gd::correct_corners` é uma implementação nova para CharacterBody2D do Godot 4: procura deslocamentos mínimos de até 4 px no pulo ou 6 px no dash lateral, verificando o caminho lateral e o avanço para evitar atravessar sólidos. Não importamos o controlador completo nem seus parâmetros de movimento.

## Comportamento documentado do TowerFall

[Towerfall AI](https://github.com/TowerfallAi/towerfall-ai) — mod que expõe estados e ações do jogo original. O README documenta tiro ao soltar, ações de pulo/dash por nova pressão, inventário por tipo e contato de parede. Usado para comparação; nenhum código ou asset do mod foi incorporado. Não é uma implementação independente do jogo.

[Celeste & TowerFall Physics, por Maddy Thorson](https://www.maddymakesgames.com/articles/celeste_and_towerfall_physics/index.html) — explicação primária da arquitetura de atores, sólidos e deslocamento por eixos. Referência conceitual; mantemos a física do Godot e não afirmamos determinismo equivalente.

## Online com rollback

[TF.EX](https://github.com/Fcornaire/TF.EX) — mod FortRise sob GPL-2.0, com netplay, rollback e replays. O README atual separa estado, replay e netplay em módulos. É referência para uma futura separação de simulação e apresentação; não é um addon pronto para Godot. Nenhum código foi copiado, e rollback não foi integrado nesta etapa.

## Resultado aplicado

- Correção de quinas no pulo e no dash, com cinco regressões específicas.
- Controle existente preservado: agarrar na parede, salto, captura, munição mista e tiro ao soltar.
- Arenas e fluxo de rodadas seguem a reconstrução local: sem HUD durante combate, saldo e totais entre rodadas.
- O jogo continua usando host autoritativo ENet por IP. Não há predição, rollback ou sala pública hospedada.
