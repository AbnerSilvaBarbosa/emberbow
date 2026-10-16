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

## Moedas, balística e replay

Seis verificações adicionais passaram em `tests/replay_ballistics.gd`: subida/queda natural, autoeliminação com perda de ponto, histórico limitado, avanço do replay, ausência de mutação de pontuação e limpeza entre rodadas. Combate, inventário/wrap e fluxo de rodadas foram revalidados. O teste ENet agora encerra uma rodada e exige replay disponível no host e nos três clientes: todos passaram. Capturas `round-score.png` e `round-replay.png` conferidas. O replay utiliza estados visuais locais; não sincroniza um arquivo de replay completo e não implementa rollback.

## Impacto de morte e novos layouts

Seis testes de `death_sequence.gd` passaram, cobrindo animação/impacto, permanência de dois sobreviventes mesmo após dez pontos, início apenas ao restar um, pausa final, rebobinada e reprodução lenta. Combate, balística e fluxo foram revalidados; quatro processos ENet passaram. Há doze layouts; spawns e passagens entre bordas testados em todos. Capturas de impacto/rebobinada/câmera lenta conferidas; intensidade de som e rumble requer playtest físico.

## Servidor dedicado e builds exportadas — 16/10/2026

Godot 4.5.1 Linux, headless, mesmos scripts do repositório.

- **Servidor dedicado:** um processo com `--server` e **três clientes ENet reais** em localhost (`tests/dedicated.py`, código de saída 0). Verificado: abertura da porta, três conexões aceitas, início automático da partida sem nenhuma ação de interface, movimento dos clientes simulado no servidor e rotação para a rodada 2 depois que a rodada terminou.
- **Build Linux Server** (preset `Linux Server`, PCK embutido): o binário exportado abriu UDP 24680 e recebeu dois clientes, que reportaram início automático e movimento — mesma verificação do pacote distribuído, não só do projeto no editor.
- **Build Windows** (preset `Windows`, x86_64, PCK embutido): exportada no Linux, 97 MB. O `.exe` **ainda não foi executado em um Windows real**, então "builds exportadas" sai da lista de não testados apenas quanto à exportação.
- Regressão completa reexecutada nesta revisão: 165 verificações de mecânicas/controle/interface, `tests/network.py` (anfitrião jogador + três clientes) e `tests/dedicated.py`.
- O servidor dedicado foi executado em uma VPS Linux (Ubuntu, headless) e recebeu dois clientes reais pelo `127.0.0.1` da própria VPS: partida iniciada automaticamente e movimento simulado no servidor. Jogadores em redes distintas, internet pública e a unidade systemd em operação contínua ainda não foram medidos.
