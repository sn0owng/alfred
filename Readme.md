# Pré-requisitos

- jq: JQ é um utilitário para a leitura de JSONs na linha de comando, para mais informações e instruções de como instalar siga a [documentação](https://stedolan.github.io/jq)

- fabric-bin: Conjunto de ferramentas disponibilizadas pelo Hyperledger para a interação na rede. Para baixar execute o script o comando:
    ```
    ./network.sh bin
    ```

- Docker: Docker é um software de contêiners, ele fornece uma camada de abstração e automação para a virtualização de SOs.

# Configurando o deploy

- Acesse o config.json e altere o `basepath`, a partir dele é que serão instalados os nós da rede.
- Também pode-se adicionar novos consórcios, usuários, canais e chaincodes.

# Realizando o deploy

- Execute o script `network.sh` passando como argumento o arquivo de configuração. Exemplo:
    ```
    ./network.sh deploy -c config.json
    ```

# Limpando a rede

- Execute o script `network.sh` passando como argumento o arquivo de configuração. Exemplo:
    ```
    ./network.sh clean -c config.json
    ```

# Limitações

- No momento só se pode ter um Orderer
- Cada Org só pode ter um peer
- Não é possível alterar canais após criados
- Não é possível realizar o update de chaincodes
- Não é possível realizar o deploy de novos chaincodes após a rede ter sido criada
- Chaincodes que utilizem private data ainda não são compatíveis com a solução