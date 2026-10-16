# Hospedar partidas e colocar em um servidor

## O que esta versão suporta

O Emberbow usa **ENet/UDP na porta 24680**, com um host que também é jogador. A sala comporta **um anfitrião + até três convidados**. O anfitrião seleciona a arena e inicia a partida pela interface.

| Cenário | Situação atual |
|---|---|
| Jogar no mesmo computador | Funciona por `127.0.0.1` entre instâncias |
| Jogar na mesma rede | Host no PC de um jogador, convidados pelo IP local |
| Jogar pela internet | Precisa de UDP acessível no host ou VPN entre participantes |
| VM Windows/Linux com interface gráfica | Pode executar o mesmo host, com operação manual; ocupa uma vaga de jogador |
| VPS Linux sem interface, automática, 24/7 | **Servidor dedicado ainda não implementado** |
| Site, GitHub Pages, hospedagem HTTP | Não hospeda o processo ENet deste jogo |

Não há códigos de sala, autenticação, relay, matchmaking, predição ou rollback. Os testes de rede realizados foram em localhost, não em uma VPS ou conexão de internet pública.

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

## Por que `--headless` sozinho não resolve uma VPS dedicada?

O Godot consegue executar sem janela, mas este projeto ainda depende do fluxo de host jogador:

- `host()` cria o personagem do servidor com `spawn(1)`.
- O início da partida é feito pela interface do anfitrião.
- A simulação trata o host como um jogador e reserva uma das quatro vagas.
- Não há comando de produção para seleção de mapa, início automático ou gerenciamento de salas.

Os argumentos `--host-test` e `--join-test` são ferramentas de teste. **Não use `tests/net_peer.gd` como serviço:** ele simula entradas, força eliminações e encerra sozinho.

Para oferecer um servidor Linux dedicado 24/7, ainda é necessário implementar:

1. Modo de execução sem personagem local e capacidade correta de clientes.
2. Entrada `--server` e configuração de porta/mapa.
3. Prontidão/início e revanche controlados pelos clientes ou por regras automáticas.
4. Reconexão, encerramento de salas vazias e logs operacionais.
5. Exportação de servidor, serviço systemd/container e teste real na infraestrutura escolhida.

Só depois disso faria sentido adicionar um `Dockerfile` de produção ou unidade systemd. Não há comando fictício de deploy neste guia.

## Escolher uma hospedagem

O requisito principal é um **processo persistente com entrada UDP acessível**. Hospedagem estática, um domínio HTTPS ou um proxy apenas TCP não atendem ao transporte atual. Antes de escolher Railway ou outro PaaS, confirme suporte a UDP público; o repositório não inclui integração nem implantação nesses serviços.

Publicar o código no GitHub não liga um servidor de partidas. Neste momento, nenhuma infraestrutura foi provisionada por este guia.

## Diagnóstico rápido

| Sintoma | Conferir |
|---|---|
| Funciona local, mas não pela internet | Encaminhamento UDP, firewall, IP público e CGNAT |
| Sala não abre | Outro processo pode estar usando UDP 24680 |
| Cliente conecta, mas não começa | O anfitrião precisa iniciar pela interface |
| VPS headless fica aguardando | Não há fluxo de servidor dedicado autônomo implementado |
| Amigos não conseguem conectar no meio da partida | Novas conexões são recusadas durante a partida |
| Movimento parece atrasado | Não há predição/rollback; latência afeta o controle remoto |
| Um host desconecta todos ao fechar | Comportamento atual: não existe migração de anfitrião |

## Fontes e código

- [Multiplayer de alto nível — Godot 4.5](https://docs.godotengine.org/en/4.5/tutorials/networking/high_level_multiplayer.html).
- [Exportação para servidores dedicados — Godot 4.5](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_dedicated_servers.html).
- [Implementação de host/cliente](../scripts/main.gd).
- [Validação e limites](VALIDATION.md).
