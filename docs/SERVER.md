# Hospedar partidas e colocar em um servidor

## O que esta versão suporta

O Emberbow usa **ENet/UDP na porta 24680**. A sala comporta quatro arqueiros. Há dois anfitriões possíveis: um **jogador** que também joga (Opções 1 e 2) ou o **servidor dedicado headless** com `--server` (Opção 3), que não ocupa vaga e abre partidas sozinho.

| Cenário | Situação atual |
|---|---|
| Jogar no mesmo computador | Funciona por `127.0.0.1` entre instâncias |
| Jogar na mesma rede | Host no PC de um jogador, convidados pelo IP local |
| Jogar pela internet | Precisa de UDP acessível no host ou VPN entre participantes |
| VM Windows/Linux com interface gráfica | Pode executar o mesmo host, com operação manual; ocupa uma vaga de jogador |
| VPS Linux sem interface, automática, 24/7 | **Suportado com `--server`**: sem personagem local, quatro vagas, início e revanche automáticos |
| Site, GitHub Pages, hospedagem HTTP | Não hospeda o processo ENet deste jogo |

Não há códigos de sala, autenticação, relay, matchmaking, predição ou rollback. Os testes de rede realizados foram em localhost, incluindo um servidor dedicado com três clientes; internet pública e VPS com latência real ainda não foram medidas.

## Opção 1 — O PC de um jogador hospeda

É o caminho disponível para uma partida normal hoje.

### Mesma rede Wi-Fi/cabo

1. Todos instalam a mesma revisão do projeto. Veja [Windows](WINDOWS.md) ou o [README](../README.md).
2. No computador do anfitrião, abra o jogo e escolha **Jogar online → Criar sala**.
3. Identifique o IPv4 da interface de rede usada. No Windows, execute `ipconfig` no terminal e procure a conexão Wi-Fi/Ethernet ativa.
4. Compartilhe o IP local, por exemplo `192.168.1.50`.
5. Cada convidado escolhe **Jogar online**, informa esse IP e clica em **Conectar**.
6. O anfitrião inicia quando houver 2–4 jogadores.

Não use `127.0.0.1` em outro computador: esse endereço sempre aponta para a própria máquina. Redes Wi-Fi de convidados podem bloquear a comunicação entre dispositivos.

### Firewall do Windows

Permita o jogo/Godot na rede utilizada quando o Windows solicitar. Para uma regra explícita na rede privada, abra **PowerShell como administrador** e ajuste o caminho do executável:

```powershell
$gameExe = 'C:\Ferramentas\Godot\Godot_v4.5.1-stable_win64.exe'
New-NetFirewallRule -DisplayName 'Emberbow UDP 24680' -Direction Inbound -Action Allow -Protocol UDP -LocalPort 24680 -Program $gameExe -Profile Private
```

Se estiver executando uma build exportada, use o caminho de `Emberbow.exe`. A regra é para o executável que realmente abre a sala. Se a interface de rede estiver no perfil Público, essa regra Privada não se aplica: escolha o perfil apropriado à rede em uso, sem desativar o firewall inteiro.

Para remover a regra criada:

```powershell
Remove-NetFirewallRule -DisplayName 'Emberbow UDP 24680'
```

### Pela internet

Além do firewall:

1. Reserve um IP local estável para o PC do anfitrião no roteador.
2. Configure encaminhamento **UDP externo 24680 → IP local do host, UDP 24680**.
3. Compartilhe o IP público da conexão com os convidados. No campo do jogo, informe apenas o IP/hostname, sem `https://` e sem `:24680`.
4. Mantenha o jogo e a sala abertos; sair fecha a sessão dos convidados.
5. Teste com alguém em outra conexão. Alguns roteadores não permitem testar o IP público de dentro da mesma rede.

Em CGNAT ou duplo NAT, a regra do roteador doméstico pode não bastar. As alternativas são obter IP público acessível com o provedor ou usar uma VPN que permita comunicação entre os participantes. Na VPN, todos entram na mesma rede virtual e usam o IP virtual do anfitrião. O jogo não configura isso automaticamente.

## Opção 2 — Executar o host numa máquina remota com interface gráfica

Esta opção usa o programa atual; **não transforma o jogo em servidor dedicado**. O processo remoto representa P1, ocupa uma vaga e precisa de operação pela interface para iniciar/reiniciar partidas. Se ninguém jogar como esse P1, ele continuará sendo um participante, afetando o combate. Para uma partida normal, prefira o PC de um dos jogadores.

### Preparação da máquina

- Sistema com sessão gráfica e suporte ao renderer Compatibility do Godot.
- Godot 4.5.1 padrão, Git ou uma cópia extraída do repositório.
- IP alcançável pelos clientes, por rede local, pública ou VPN.
- Entrada **UDP 24680** permitida tanto no firewall do sistema quanto nas regras de rede do provedor.
- Acesso remoto privado à sessão gráfica para operar o jogo; a porta do jogo não dá acesso à área de trabalho.

Não há dimensionamento de CPU/RAM ou capacidade de produção medidos. A sala continua limitada a quatro participantes totais.

### Copiar e abrir

No Windows, siga [o guia Windows](WINDOWS.md), usando a pasta da máquina remota. Em Linux **com sessão gráfica**, depois de instalar o Godot 4.5.1 e disponibilizar `godot` no PATH:

```sh
git clone https://github.com/AbnerSilvaBarbosa/emberbow.git
cd emberbow
godot --headless --path . --editor --import --quit
godot --path .
```

O comando com `--headless` acima serve apenas para importar recursos. O comando final abre o jogo normal na sessão gráfica. Depois:

1. Selecione a arena e crie a sala pelo menu.
2. Os convidados conectam ao IP alcançável dessa máquina.
3. Inicie pela interface do host.
4. Mantenha a sessão e o processo em execução.

Em um Linux que já usa UFW, a regra correspondente é:

```sh
sudo ufw allow 24680/udp comment 'Emberbow'
sudo ufw status
```

Isso não substitui as regras de rede/security group do provedor. A documentação não recomenda ativar/reconfigurar UFW às cegas numa máquina acessada por SSH.

### Conferir se há processo ouvindo

Windows, após criar a sala:

```powershell
Get-NetUDPEndpoint -LocalPort 24680
```

Linux:

```sh
ss -lunp 'sport = :24680'
```

Esses comandos verificam o socket local, não a conectividade externa. `Test-NetConnection -Port` testa TCP, portanto não confirma a porta UDP do Emberbow. A prova final é outro cliente entrar na sala pela rede desejada.

## Opção 3 — Servidor dedicado headless

É o caminho para uma VPS sem interface: ninguém precisa operar o jogo. A build com `--server` abre a sala sem criar personagem local, então as **quatro vagas** ficam para os clientes.

```sh
# Linux: binário do pacote Emberbow-Server-Linux (recursos embutidos).
./emberbow-server --headless -- --server --port=24680 --map=0
```

| Argumento | Efeito |
|---|---|
| `--server` | Abre a sala dedicada, sem arqueiro local. Builds exportadas com a feature `dedicated_server` já iniciam assim, sem precisar do argumento. |
| `--port=` | Porta UDP. Padrão 24680. |
| `--map=` | Índice da arena, de 0 a 11. Padrão 0 (Ruínas da Aurora). |

Como as rodadas se comportam sem anfitrião humano:

- Cada cliente que conecta ocupa uma vaga; o servidor escreve `EMBERBOW_PEER_JOIN`, `EMBERBOW_PEER_LEFT` e `EMBERBOW_SERVER_READY` no log.
- Com **dois ou mais** arqueiros na sala, a partida começa 4 s depois, sem clique nenhum.
- Ao final de um jogo (alguém chega a 10 pontos), uma nova partida começa 8 s depois. Os pontos são zerados.
- Se um jogador sair no meio e sobrar menos de dois, a rodada é cancelada e a sala volta a aguardar — igual ao anfitrião humano.
- Durante a partida, conexões novas continuam sendo recusadas; elas entram na próxima.

### Instalar como serviço systemd

O repositório inclui `server/emberbow.service`, que roda o servidor como usuário `emberbow` em `/opt/emberbow/current`:

```sh
sudo useradd --system --no-create-home --shell /usr/sbin/nologin emberbow
sudo install -d -m 755 /opt/emberbow/current
sudo install -m 755 emberbow-server /opt/emberbow/current/
sudo install -m 644 emberbow.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now emberbow

systemctl status emberbow
sudo ss -lunp 'sport = :24680'
journalctl -u emberbow -n 20 --no-pager -o cat
```

A unidade fixa `--port=24680 --map=0` no `ExecStart`; edite a linha e rode `systemctl daemon-reload` para mudar. O `stdbuf -oL` existe só para as linhas `EMBERBOW_*` aparecerem no journal no momento em que acontecem: sem ele o stdout do Godot fica em buffer e só é despejado no fim do processo. Libere **UDP 24680** no firewall do sistema **e** nas regras do provedor (security group). Os comandos de conferência de socket não provam conectividade externa: a prova é um cliente real entrando de outra rede.

O pacote `Emberbow-Server-Linux` traz o binário, esta unidade e as licenças. Para gerar de novo a partir do código:

```sh
python3 tools/build_release.py --godot /caminho/para/godot
```

### Conferir um servidor que já está no ar

Olhar o socket só diz que a porta está aberta. Para uma prova de verdade, aponte dois clientes para o servidor — em dois terminais, no mesmo diretório do projeto:

```sh
godot --headless --path . --script tests/live_join.gd
```

Cada processo imprime `LIVE_JOIN_PASS` ao conectar, ver o início automático da partida e ter o próprio movimento simulado pelo servidor. Com um cliente só, a partida não começa: são necessários dois arqueiros.

### O que o servidor dedicado ainda não faz

- Sem códigos de sala, senha, autenticação, relay ou matchmaking.
- Sem reconexão durante a partida nem migração de anfitrião.
- Sem encerramento automático de sala vazia (o processo continua ouvindo a porta).
- Sem predição/rollback por cliente: a latência alta continua afetando o controle remoto.
- Sem Dockerfile nem container de produção.

Os argumentos `--host-test` e `--join-test` continuam sendo ferramentas de teste. **Não use `tests/net_peer.gd` como serviço:** ele simula entradas, força eliminações e encerra sozinho.

## Escolher uma hospedagem

O requisito principal é um **processo persistente com entrada UDP acessível**. Hospedagem estática, um domínio HTTPS ou um proxy apenas TCP não atendem ao transporte atual. Antes de escolher Railway ou outro PaaS, confirme suporte a UDP público; o repositório não inclui integração nem implantação nesses serviços.

Publicar o código no GitHub não liga um servidor de partidas. Neste momento, nenhuma infraestrutura foi provisionada por este guia.

## Diagnóstico rápido

| Sintoma | Conferir |
|---|---|
| Funciona local, mas não pela internet | Encaminhamento UDP, firewall, IP público e CGNAT |
| Sala não abre | Outro processo pode estar usando UDP 24680 |
| Cliente conecta, mas não começa | No servidor dedicado, aguarde o segundo arqueiro e 4 s; num host jogador, o anfitrião inicia pela interface |
| VPS headless fica aguardando para sempre | Faltou `--server` (ou a build não tem a feature `dedicated_server`); confira a linha `EMBERBOW_SERVER_READY` no log |
| Amigos não conseguem conectar no meio da partida | Novas conexões são recusadas durante a partida |
| Movimento parece atrasado | Não há predição/rollback; latência afeta o controle remoto |
| Um host desconecta todos ao fechar | Comportamento atual: não existe migração de anfitrião |

## Fontes e código

- [Multiplayer de alto nível — Godot 4.5](https://docs.godotengine.org/en/4.5/tutorials/networking/high_level_multiplayer.html).
- [Exportação para servidores dedicados — Godot 4.5](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_dedicated_servers.html).
- [Implementação de host/cliente](../scripts/main.gd).
- [Validação e limites](VALIDATION.md).
