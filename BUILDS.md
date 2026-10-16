# Builds do Emberbow

Esta branch existe só para deixar o pacote pronto a um clique enquanto o
repositório não tem uma Release publicada. O código continua na `main` — aqui
não há fonte, só o arquivo gerado por `tools/build_release.py` na mesma revisão.

## Windows

[`Emberbow-Windows-0.1.0.zip`](Emberbow-Windows-0.1.0.zip) — 34 MB. Extraia e
abra `Emberbow.exe`: os recursos vão embutidos no executável e as licenças
acompanham o ZIP. Não é preciso instalar o Godot.

Gerado com Godot 4.5.1 (preset **Windows**, x86_64, PCK embutido), exportado no
Linux. A execução num Windows real ainda não foi conferida por quem publicou.

## Servidor Linux

O pacote do servidor dedicado sai do mesmo script (`Emberbow-Server-Linux`). Um
binário equivalente está rodando numa VPS Linux agora; a unidade systemd que
mantém esse tipo de servidor de pé está em `server/emberbow.service` na `main`.

```sh
python3 tools/build_release.py --godot /caminho/para/godot
```
