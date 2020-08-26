### INIT VARS
export CONFIGTX_PATH=$BASE_PATH/configtx
export FABRIC_CFG_PATH=$CONFIGTX_PATH
export CORE_PEER_TLS_ENABLED=true

### CALCULATE TOTAL CHAINCODES TO INSTALL
TOTAL_CHAINCODES=$(cat $CONFIG| jq -r '.chaincodes' | jq length)
TOTAL_CHAINCODES=$(($TOTAL_CHAINCODES-1))

## SET ORDERER INFOS
ORDERER=$(cat $CONFIG | jq -r '.orgs[] | select(.peer.type=="Orderer")')
ORDERER_NAME=$(echo $ORDERER | jq -r '.name')
ORDERER_DOMAIN=$(echo $ORDERER | jq -r '.domain')
ORDERER_NAME_LOWER=$(echo "$ORDERER_NAME" | tr '[:upper:]' '[:lower:]')
ORDERER_PEER=$(echo $ORDERER | jq -r '.peer.name')
ORDERER_PORT=$(echo $ORDERER | jq -r '.peer.port')
ORDERER_TLS=$BASE_PATH/${ORDERER_NAME_LOWER}.${ORDERER_DOMAIN}/tlsca/tlsca.${ORDERER_NAME_LOWER}.${ORDERER_DOMAIN}-cert.pem

function package() {
    peer lifecycle chaincode package ${CHAINCODE_TAR_PATH} --path ${CHAINCODE_PATH} --lang ${CHAINCODE_LANG} --label ${CHAINCODE_NAME}
}

### INSTALL CHAINCODES
for counter in $(seq 0 $TOTAL_CHAINCODES); do
    ### RECOVER CHAINCODE INFO
    CHAINCODE=$(cat $CONFIG | jq -r ".chaincodes[$counter]")
    CHAINCODE_NAME=$(echo $CHAINCODE | jq -r ".name")
    CHAINCODE_PATH=$(echo $CHAINCODE | jq -r ".path")
    CHAINCODE_LANG=$(echo $CHAINCODE | jq -r ".lang")
    CHAINCODE_VERSION=$(echo $CHAINCODE | jq -r ".version")
    CHAINCODE_SEQUENCE=$(echo $CHAINCODE | jq -r ".sequence")
    CHAINCODE_CHANNEL=$(echo $CHAINCODE | jq -r ".channel")
    CHAINCODE_CHANNEL_LOWER=$(echo "$CHAINCODE_CHANNEL" | tr '[:upper:]' '[:lower:]')
    CHAINCODE_TAR_PATH=/tmp/${CHAINCODE_NAME}.tar.gz

    if [[ "$CHAINCODE_PATH" == "" ]]; then
        CHAINCODE_PATH=${PARENTH_PATH}/chaincodes/${CHAINCODE_NAME}
    fi

    ### PACKAGE CHAINCODE
    package

    ### INSTALL AND APROVE IN EACH ORG
    CHANNEL=$(cat $CONFIG | jq -r ".channels[] | select(.name==\"${CHAINCODE_CHANNEL}\")")

    ### CALCULATE TOTAL ORGS ON CONSORT
    TOTAL_ORGS_CONSORT=$(echo $CHANNEL | jq -r '.orgs' | jq length)
    TOTAL_ORGS_CONSORT=$(($TOTAL_ORGS_CONSORT - 1))
    
    ### GENERATE ORGS ANCHORS
    for orgCounter in $(seq 0 $TOTAL_ORGS_CONSORT); do
        ### RECOVER ORG INFO
        ORG=$(echo $CHANNEL | jq -r ".orgs[$orgCounter]")
        ORG_OBJ=$(cat $CONFIG | jq -r ".orgs[] | select(.name==\"${ORG}\")")
        ORG_NAME=$(echo $ORG_OBJ | jq -r '.name')
        ORG_DOMAIN=$(echo $ORG_OBJ | jq -r '.domain')
        ORG_NAME_LOWER=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')
        ORG_HOME=${BASE_PATH}/${ORG_NAME_LOWER}.${ORG_DOMAIN}
        PEER_NAME=$(echo $ORG_OBJ | jq -r '.peer.name')
        PEER_PORT=$(echo $ORG_OBJ | jq -r '.peer.port')

        ### SET TOOLS CONFIG
        export CORE_PEER_LOCALMSPID="${ORG_NAME}MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=${ORG_HOME}/peers/${PEER_NAME}.${ORG_NAME_LOWER}.${ORG_DOMAIN}/tls/ca.crt
        export CORE_PEER_MSPCONFIGPATH=${ORG_HOME}/users/${ORG_NAME_LOWER}admin@${ORG_NAME_LOWER}.${ORG_DOMAIN}/msp
        export CORE_PEER_ADDRESS=localhost:${PEER_PORT}

        ### INSTALL CHAINCODE
        peer lifecycle chaincode install $CHAINCODE_TAR_PATH 

        peer lifecycle chaincode queryinstalled >&/tmp/pkg.txt

        CC_PACKAGE_ID=$(sed -n "/${CHAINCODE_NAME}/{s/^Package ID: //; s/, Label:.*$//; p;}" /tmp/pkg.txt)

        ### APROVE CHAINCODE
        peer lifecycle chaincode approveformyorg -o localhost:${ORDERER_PORT} \
        --ordererTLSHostnameOverride ${ORDERER_PEER}.${ORDERER_NAME}.${ORDERER_DOMAIN} \
        --channelID ${CHAINCODE_CHANNEL_LOWER} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} \
        --package-id $CC_PACKAGE_ID --sequence ${CHAINCODE_SEQUENCE} --tls \
        --cafile $ORDERER_TLS

        ### INCREMENT PEERS
        PEERS="${PEERS} --peerAddresses ${CORE_PEER_ADDRESS} --tlsRootCertFiles ${CORE_PEER_TLS_ROOTCERT_FILE}"
    done

    peer lifecycle chaincode commit -o localhost:${ORDERER_PORT} \
    --ordererTLSHostnameOverride ${ORDERER_PEER}.${ORDERER_NAME}.${ORDERER_DOMAIN} \
    --channelID ${CHAINCODE_CHANNEL_LOWER} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --sequence ${CHAINCODE_SEQUENCE} \
    --tls --cafile $ORDERER_TLS\
    $PEERS

    ### JUST FOR EXAMPLE
    # peer chaincode invoke -o localhost:${ORDERER_PORT} --ordererTLSHostnameOverride ${ORDERER_PEER}.${ORDERER_NAME}.${ORDERER_DOMAIN} --tls \
    # --cafile ${ORDERER_TLS} \
    # -C ${CHAINCODE_CHANNEL_LOWER} -n ${CHAINCODE_NAME}\
    # ${PEERS} \
    # -c '{"function":"initLedger","Args":[]}'
    # peer chaincode query -C ${CHAINCODE_CHANNEL_LOWER} -n ${CHAINCODE_NAME} -c '{"Args":["queryAllCars"]}'
done