# Pré-requisitos

- jq: JQ é um utilitário para a leitura de JSONs na linha de comando, para mais informações e instruções de como instalar siga a [documentação](https://stedolan.github.io/jq)

- fabric-bin: Conjunto de ferramentas disponibilizadas pelo Hyperledger para a interação na rede. Para baixar execute o script o comando:
    ```
    ./network.sh bin
    ```

- Docker: Docker é um software de contêiners, ele fornece uma camada de abstração e automação para a virtualização de SOs.

# Configurando o deploy

- Acesse o config.json e altere o `basepath`, a partir dele é que serão instalados os nós da rede.
  Obs: Caso seja deixado em branco, o script irá criar a rede no diretório do repositório, dentro da pasta "/network"
- Também pode-se adicionar novos consórcios, usuários, canais e chaincodes.
- Pode-se deixar o path do chaincode em branco, sendo apenas necessário colocar ele na pasta `chaincodes` do repositório em uma pasta com o mesmo nome que o chaincode.

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
# Hotdeploy Chaincode

- Para realizar o hot deployment de um **CHAINCODE** basta utilizar o script `deployCC.sh` passando como parametro:
   - Nome do chaincode ( -na ) - Obrigatório
   - Caminhao do chaincode ( -p ) - Obrigatório
   - Canal do chaincode ( -c ) - Obrigatório
   - Versão do chaincode ( -v ) - Opcional
   - Indicação da utilização de Private Date / Caminho do Private Data ( --private ) Opcional

  Os comandos acima devem estar na ordem para funcionarem

- Para realizar um upgrade de um **CHAINCODE** é necessario apenas executar o script passando o mesmo **nome** do chaincode com uma versão diferente. Neste caso o uso da **versão** se torna obrigatório. 


# Limitações

- No momento só se pode ter um Orderer
- Cada Org só pode ter um peer
- Não é possível alterar canais após criados