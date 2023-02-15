# Unigrid Docker Image Builder

Build commands

Main

```
docker build --no-cache . --tag=unigrid/unigrid:latest
```

Testnet

```
docker build --no-cache . --tag=unigrid/unigrid:testnet
docker build --no-cache --progress=plain . --tag=unigrid/unigrid:testnet &> output.txt
```


