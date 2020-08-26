### INIT CONFIG TX FILE
CONFIGTX_FILE=$CONFIGTX_PATH/configtx.yaml

mkdir -p $CONFIGTX_PATH

echo "Organizations:" > $CONFIGTX_FILE

### FUNCTIONS
function plotBaseNode() {
    echo "    - &<ORG_NAME>
        Name: <ORG_NAME>Org
        ID: <ORG_NAME>MSP
        MSPDir: <ORG_MSP_PATH>
        Policies:
            Readers:
                Type: Signature
                Rule: \"OR('<ORG_NAME>MSP.member')\"
            Writers:
                Type: Signature
                Rule: \"OR('<ORG_NAME>MSP.member')\"
            Admins:
                Type: Signature
                Rule: \"OR('<ORG_NAME>MSP.admin')\"" >> $CONFIGTX_FILE
}

## DO ANYTHING FOR EACH ORG
for counter in $(seq 0 $TOTAL_ORGS); do
    ### INIT ORG VARS
    ORG_OBJ=$(cat $CONFIG | jq -r ".orgs[$counter]")
    ORG=$(echo $ORG_OBJ | jq -r '.name')
    DOMAIN=$(echo $ORG_OBJ | jq -r '.domain')
    ORG_LOWER=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')
    ORG_TYPE=$(echo $ORG_OBJ | jq -r '.peer.type')
    ORG_HOME=${BASE_PATH}/${ORG_LOWER}.${DOMAIN}
    PNAME=$(echo $ORG_OBJ | jq -r '.peer.name')
    PORT=$(echo $ORG_OBJ | jq -r '.peer.port')
    ### GENFILE
    plotBaseNode
    sed -i'' -e "s/<ORG_NAME>/$ORG/" $CONFIGTX_FILE
    sed -i'' -e "s,<ORG_MSP_PATH>,$ORG_HOME/msp," $CONFIGTX_FILE
    if [[ $ORG_TYPE == "Orderer" ]]; then
        echo "        OrdererEndpoints:
            - <PEER_NAME>.<ORG_NAME>.<DOMAIN>:<PORT>" >> $CONFIGTX_FILE
        sed -i'' -e "s/<PEER_NAME>/$PNAME/" $CONFIGTX_FILE
        sed -i'' -e "s/<ORG_NAME>/$ORG_LOWER/" $CONFIGTX_FILE
        sed -i'' -e "s/<DOMAIN>/$DOMAIN/" $CONFIGTX_FILE
        sed -i'' -e "s/<PORT>/$PORT/" $CONFIGTX_FILE
    else
        echo "            Endorsement:
                Type: Signature
                Rule: \"OR('<ORG_NAME>MSP.peer')\"
        AnchorPeers:
            - Host: <PEER_NAME>.<ORG_NAME>.<DOMAIN>
              Port: <PORT>" >> $CONFIGTX_FILE
        
        sed -i'' -e "0,/<ORG_NAME>/ s/<ORG_NAME>/$ORG/" $CONFIGTX_FILE
        sed -i'' -e "0,/<ORG_NAME>/ s/<ORG_NAME>/$ORG_LOWER/" $CONFIGTX_FILE

        sed -i'' -e "s/<PEER_NAME>/$PNAME/" $CONFIGTX_FILE

        sed -i'' -e "s/<DOMAIN>/$DOMAIN/" $CONFIGTX_FILE
        
        sed -i'' -e "s/<PORT>/$PORT/" $CONFIGTX_FILE
    fi
done

### PLOT ORDERER DEFAULT
cat $TEMPLATES/configtx-template_1.yaml >> $CONFIGTX_FILE
ORDERER=$(cat $CONFIG | jq -r '.orgs[] | select(.peer.type=="Orderer")')
ORG=$(echo $ORDERER | jq -r '.name')
DOMAIN=$(echo $ORDERER | jq -r '.domain')
ORG_LOWER=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')
PNAME=$(echo $ORDERER | jq -r '.peer.name')
PORT=$(echo $ORDERER | jq -r '.peer.port')
TLS=$BASE_PATH/${ORG_LOWER}.${DOMAIN}/peers/${ORG_LOWER}.${ORG_LOWER}.${DOMAIN}/tls/server.crt

sed -i'' -e "s/<PEER_NAME>/$PNAME/" $CONFIGTX_FILE
sed -i'' -e "s/<ORDER_ORG>/$ORG_LOWER/" $CONFIGTX_FILE
sed -i'' -e "s/<ORDER_PORT>/$PORT/" $CONFIGTX_FILE
sed -i'' -e "s/<ORDER_DOMAIN>/$DOMAIN/" $CONFIGTX_FILE
sed -i'' -e "s,<ORDER_TLS_CERT>,$TLS," $CONFIGTX_FILE

### PLOT GENESIS
GENESIS_NAME=$(cat $CONFIG | jq -r '.genesis.name')
echo "
Profiles:
    ${GENESIS_NAME}:
        <<: *ChannelDefaults
        Orderer:
            <<: *OrdererDefaults
            Organizations:
                - *${ORG}
            Capabilities:
                <<: *OrdererCapabilities
        Consortiums:" >> $CONFIGTX_FILE

### CALC TOTAL CONSORTIUM
TOTAL_CONSORTIUM=$(cat $CONFIG | jq -r '.genesis.consortiums' | jq length)
TOTAL_CONSORTIUM=$(($TOTAL_CONSORTIUM-1))

### PLOT CONSORTIUM
function plotConsortium() {
    CONSORTIUM_NAME=$(echo $CONSORTIUM_OBJ | jq -r '.name')
    echo "            ${CONSORTIUM_NAME}:
                Organizations:" >> $CONFIGTX_FILE
    TOTAL_ORGS_CONSORT=$(echo $CONSORTIUM_OBJ | jq -r '.orgs' | jq length)
    TOTAL_ORGS_CONSORT=$(($TOTAL_ORGS_CONSORT-1))
    for org_counter in $(seq 0 $TOTAL_ORGS_CONSORT); do
        CONSORTIUM_ORG_NAME=$(echo $CONSORTIUM_OBJ | jq -r ".orgs[$org_counter]")
        echo "                    - *${CONSORTIUM_ORG_NAME}" >> $CONFIGTX_FILE
    done
}

### DO ANYTHING FOR EACH CONSORTIUM
for counter in $(seq 0 $TOTAL_CONSORTIUM); do
    CONSORTIUM_OBJ=$(cat $CONFIG | jq -r ".genesis.consortiums[$counter]")
    plotConsortium
done

## CALC TOTAL CHANNELS
TOTAL_CHANNELS=$(cat $CONFIG | jq -r '.channels' | jq length)
TOTAL_CHANNELS=$(($TOTAL_CHANNELS-1))

### PLOT CHANNEL
function plotChannel() {
    CHANNEL_NAME=$(echo $CHANNEL_OBJ | jq -r '.name')
    CHANNEL_CONSORT=$(echo $CHANNEL_OBJ | jq -r '.consortium')
    echo "    ${CHANNEL_NAME}:
        Consortium: ${CHANNEL_CONSORT}
        <<: *ChannelDefaults
        Application:
            <<: *ApplicationDefaults
            Organizations:" >> $CONFIGTX_FILE
    TOTAL_ORGS_CHANNEL=$(echo $CHANNEL_OBJ | jq -r '.orgs' | jq length)
    TOTAL_ORGS_CHANNEL=$(($TOTAL_ORGS_CHANNEL-1))
    for org_counter in $(seq 0 $TOTAL_ORGS_CHANNEL); do
        CHANNEL_ORG_NAME=$(echo $CHANNEL_OBJ | jq -r ".orgs[$org_counter]")
        echo "                - *${CHANNEL_ORG_NAME}" >> $CONFIGTX_FILE
    done
    echo "            Capabilities:
                <<: *ApplicationCapabilities" >> $CONFIGTX_FILE
}

### DO ANYTHING FOR EACH CHANNEL
for counter in $(seq 0 $TOTAL_CHANNELS); do
    CHANNEL_OBJ=$(cat $CONFIG | jq -r ".channels[$counter]")
    plotChannel
done

cp $TEMPLATES/core.yaml $CONFIGTX_PATH/core.yaml