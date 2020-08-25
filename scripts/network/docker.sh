### INIT VARS
DOCKER_PATH=$BASE_PATH/docker

mkdir -p $DOCKER_PATH

echo "version: '2'
networks:
  test:
services:" > $DOCKER_PATH/network-compose.yaml

function initVars() {
    ### INIT ORG VARS
    ORG_OBJ=$(cat $CONFIG | jq -r ".orgs[$counter]")
    ORG=$(echo $ORG_OBJ | jq -r '.name')
    DOMAIN=$(echo $ORG_OBJ | jq -r '.domain')
    ORG_LOWER=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')
    ORG_TYPE=$(echo $ORG_OBJ | jq -r '.peer.type')
    ORG_HOME=${BASE_PATH}/${ORG_LOWER}.${DOMAIN}
    PNAME=$(echo $ORG_OBJ | jq -r '.peer.name')
    PORT=$(echo $ORG_OBJ | jq -r '.peer.port')
    PEER_FOLDER=${ORG_HOME}/peers/${PNAME}.${ORG_LOWER}.${DOMAIN}
    MSP_PATH=${PEER_FOLDER}/msp
    TLS_PATH=${PEER_FOLDER}/tls
}

function plotOrdererService() {
    echo "  $PNAME.$ORG_LOWER.$DOMAIN:
    container_name: $PNAME.$ORG_LOWER.$DOMAIN
    image: hyperledger/fabric-orderer:2.2
    environment:
      - FABRIC_LOGGING_SPEC=INFO
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_LISTENPORT=$PORT
      - ORDERER_GENERAL_GENESISMETHOD=file
      - ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block
      - ORDERER_GENERAL_LOCALMSPID=${ORG}MSP
      - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
      - ORDERER_GENERAL_TLS_ENABLED=true
      - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      - ORDERER_KAFKA_TOPIC_REPLICATIONFACTOR=1
      - ORDERER_KAFKA_VERBOSE=true
      - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric
    command: orderer
    volumes:
        - ${BASE_PATH}/artifacts/genesis/system-genesis.block:/var/hyperledger/orderer/orderer.genesis.block
        - ${MSP_PATH}:/var/hyperledger/orderer/msp
        - ${TLS_PATH}:/var/hyperledger/orderer/tls
    ports:
      - $PORT:$PORT
    networks:
      - test" >> $DOCKER_PATH/network-compose.yaml
}

function plotEndorserOrg() {
    echo "  ${PNAME}.${ORG_LOWER}.${DOMAIN}:
    container_name: ${PNAME}.${ORG_LOWER}.${DOMAIN}
    image: hyperledger/fabric-peer:2.2
    environment:
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=docker_test
      - FABRIC_LOGGING_SPEC=INFO
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_PROFILE_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      - CORE_PEER_ID=${PNAME}.${ORG_LOWER}.${DOMAIN}
      - CORE_PEER_ADDRESS=${PNAME}.${ORG_LOWER}.${DOMAIN}:${PORT}
      - CORE_PEER_LISTENADDRESS=0.0.0.0:${PORT}
      - CORE_PEER_CHAINCODEADDRESS=${PNAME}.${ORG_LOWER}.${DOMAIN}:$(($PORT+1))
      - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:$(($PORT+1))
      - CORE_PEER_GOSSIP_BOOTSTRAP=${PNAME}.${ORG_LOWER}.${DOMAIN}:${PORT}
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=${PNAME}.${ORG_LOWER}.${DOMAIN}:${PORT}
      - CORE_PEER_LOCALMSPID=Org1MSP
    volumes:
        - /var/run/:/host/var/run/
        - ${MSP_PATH}:/etc/hyperledger/fabric/msp
        - ${TLS_PATH}:/etc/hyperledger/fabric/tls
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: peer node start
    ports:
      - ${PORT}:${PORT}
    networks:
      - test" >> $DOCKER_PATH/network-compose.yaml
}

## GENERATE DOCKER SERVICE FOR EACH ORG
for counter in $(seq 0 $TOTAL_ORGS); do
   initVars
   if [[ $ORG_TYPE == "Orderer" ]]; then
    plotOrdererService
   else
    plotEndorserOrg
   fi
done

### UP CONTAINERS
docker-compose -f $DOCKER_PATH/network-compose.yaml up -d