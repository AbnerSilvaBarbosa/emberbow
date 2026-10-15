# Validação — 14/10/2026

Godot 4.5.1 macOS, renderer Compatibility/OpenGL.

- Importação de assets e carregamento dos scripts concluídos.
- **93 verificações passaram:** oito de combate, onze de mecânicas/interface, trinta de inventário/passagem entre bordas e oito de agarrar/soltar/saltar da parede e recuperar flechas, mais 31 de fluxo de rodadas, ausência de HUD e posições de nascimento nas seis arenas, e cinco de correção de quinas.
- Combate: dano/ponto, captura, explosão inclusive no dono, pisão/rebate, perfuração, colisão normal, coleta e altura do pulo.
- Mecânicas/interface: segurar/soltar tiro, ausência de repetição automática, recarga do dash, prevenção de segundo pulo no ar, pulo curto, pausa/retomada, seleção de mapa/personagem e página online.
- Inventário/mapas: tipos misturados, tipo disparado, alternância, captura, capacidade máxima; passagem vertical preservando velocidade, passagem nas duas laterais e abertura inferior nos seis mapas; flecha atravessando a borda vertical.
- **Quatro processos ENet em localhost:** host e três clientes. Todos retornaram NETWORK_PASS, verificando movimento remoto, aparência e inventário misto sincronizado. Sem erro de script ou aviso de tamanho de pacote.
- **UI_PASS:** clique por eventos de mouse no botão de treino. O teste anterior omitia o movimento do ponteiro antes de pressionar; corrigido em `tests/ui_click.gd` e `tests/capture.gd`.
- Menu, conexão, controles, pausa, resultados e seis arenas renderizados pelo Godot e inspecionados. Menu também conferido em 1280×800. Capturas em `docs/` usam uma partida montada pelo teste para mostrar quatro personagens e diferentes inventários; não representam quatro pessoas jogando.

A execução de rede usa permissão fora do sandbox para abrir sockets UDP. Dentro do sandbox, o macOS pode emitir erro ao consultar certificados do sistema; isso não ocorreu no teste final de rede.

Ainda não validados: duas máquinas físicas, internet pública, NAT, latência/perda/jitter, controles físicos, exportação Windows/Linux/web e balanceamento prolongado. Não há servidor público implantado. O teste localhost não comprova qualidade de combate em redes reais.

A nova composição usa uma grade de 24 px para desenho e colisão. Capturas atualizadas: `arena.png`, `arena-1.png` a `arena-5.png`, `round-intro.png` e `round-score.png`. O placar de captura usa dados de demonstração para exibir ganho, perda e saldo zero. Os testes unitários de combate usam uma geometria fixa isolada; as passagens, os spawns e o teste ENet usam as arenas reais.

## Controle

Doze verificações adicionais em `tests/gamepad.gd` passaram: atribuição sem/um/dois controles, deadzone, mira independente, botões, gatilho, D-pad, confirmação de menu por evento de controle, pausa/retomada e desconexão. Mecânicas existentes e clique de mouse foram revalidados. Os testes usam dados e eventos sintetizados, sem controle físico conectado; compatibilidade de modelos e Bluetooth/USB ainda depende de validação física.
