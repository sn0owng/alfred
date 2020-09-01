### GENERATE CHANNEL TX
function generateChannelTx() {
    configtxgen -profile $CHANNEL -outputCreateChannelTx $ARTIFACTS_PATH/channels/$CHANNEL_LOWER/$CHANNEL_LOWER.tx -channelID $CHANNEL_LOWER -configPath $CONFIGTX_PATH
}

### GENERATE ORG ANCHOR PEER
function generateAnchoorPeer() {
    configtxgen -profile $CHANNEL -outputAnchorPeersUpdate $ARTIFACTS_PATH/channels/$CHANNEL_LOWER/${ORG}MSPanchors.tx -channelID $CHANNEL_LOWER -asOrg ${ORG}Org -configPath $CONFIGTX_PATH
}

### CREATE CHANNEL
function createChannel() {
    peer channel create -o localhost:${ORDERER_PORT} -c $CHANNEL_LOWER \
        --ordererTLSHostnameOverride ${ORDERER_PEER}.${ORDERER_NAME}.${ORDERER_DOMAIN} \
        -f $ARTIFACTS_PATH/channels/$CHANNEL_LOWER/$CHANNEL_LOWER.tx \
        --outputBlock $ARTIFACTS_PATH/channels/$CHANNEL_LOWER/$CHANNEL_LOWER.block \
        --tls --cafile $ORDERER_TLS
}

## CALC TOTAL CHANNELS
TOTAL_CHANNELS=$(cat $CONFIG | jq -r '.channels' | jq length)
TOTAL_CHANNELS=$(($TOTAL_CHANNELS - 1))

## SET ORDERER INFOS
ORDERER=$(cat $CONFIG | jq -r '.orgs[] | select(.peer.type=="Orderer")')
ORDERER_NAME=$(echo $ORDERER | jq -r '.name')
ORDERER_DOMAIN=$(echo $ORDERER | jq -r '.domain')
ORDERER_NAME_LOWER=$(echo "$ORDERER_NAME" | tr '[:upper:]' '[:lower:]')
ORDERER_PEER=$(echo $ORDERER | jq -r '.peer.name')
ORDERER_PORT=$(echo $ORDERER | jq -r '.peer.port')
ORDERER_TLS=$BASE_PATH/${ORDERER_NAME_LOWER}.${ORDERER_DOMAIN}/tlsca/tlsca.${ORDERER_NAME_LOWER}.${ORDERER_DOMAIN}-cert.pem

### BASIC SETTINGS
export CORE_PEER_TLS_ENABLED=true

### CREATE EACH CHANNEL
for counter in $(seq 0 $TOTAL_CHANNELS); do

    CHANNEL_OBJ=$(cat $CONFIG | jq -r ".channels[$counter]")
    CHANNEL=$(echo "$CHANNEL_OBJ" | jq -r '.name')
    CHANNEL_LOWER=$(echo "$CHANNEL" | tr '[:upper:]' '[:lower:]')

    generateChannelTx

    ### CALCULATE TOTAL ORGS ON CONSORT
    TOTAL_ORGS_CONSORT=$(echo $CHANNEL_OBJ | jq -r '.orgs' | jq length)
    TOTAL_ORGS_CONSORT=$(($TOTAL_ORGS_CONSORT - 1))
    
    ### GENERATE ORGS ANCHORS
    for orgCounter in $(seq 0 $TOTAL_ORGS_CONSORT); do

        ### RECOVER ORG INFO
        ORG=$(echo $CHANNEL_OBJ | jq -r ".orgs[$orgCounter]")
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

        ### CREATE CHANNEL
        if [[ -z $CREATED ]]; then
            createChannel
            CREATED="OK"
        fi

        ### GENERATE ANCHOR PEER TX
        generateAnchoorPeer
        ### JOIN PEER ON CHANNEL
        peer channel join -b $ARTIFACTS_PATH/channels/$CHANNEL_LOWER/$CHANNEL_LOWER.block
        ### UPDATE ANCHOR PEER ON CHANNEL
        peer channel update -o localhost:${ORDERER_PORT} \
            --ordererTLSHostnameOverride ${ORDERER_PEER}.${ORDERER_NAME}.${ORDERER_DOMAIN} \
            -c $CHANNEL_LOWER -f $ARTIFACTS_PATH/channels/$CHANNEL_LOWER/${ORG_NAME}MSPanchors.tx \
            --tls --cafile $ORDERER_TLS
    done

    unset CREATED
done