#!/bin/bash
export FABRIC_CFG_PATH=${PWD}/network/configtx
export CORE_PEER_TLS_ENABLED=true
export PATH="${PWD}/bin:$PATH"

CONFIG=$PWD/config.json
ORDERER=$(cat $CONFIG | jq -r '.orgs[] | select(.peer.type=="Orderer")')
ORDERER_NAME=$(echo $ORDERER | jq -r '.name')
ORDERER_DOMAIN=$(echo $ORDERER | jq -r '.domain')
ORDERER_NAME_LOWER=$(echo "$ORDERER_NAME" | tr '[:upper:]' '[:lower:]')
ORDERER_PEER=$(echo $ORDERER | jq -r '.peer.name')
ORDERER_PORT=$(echo $ORDERER | jq -r '.peer.port')
ORDERER_TLS=$PWD/network/${ORDERER_NAME_LOWER}.${ORDERER_DOMAIN}/tlsca/tlsca.${ORDERER_NAME_LOWER}.${ORDERER_DOMAIN}-cert.pem

function helpMessage(){
    echo "Para dar UPDATE não esqueça de enviar um NAMESPACE ( -n ) já existente e uma VERSÃO DIFERENTE ( -v ) - A sequencia é feita automaticamente"
    echo "Devem ser enviados os seguintes parametros em sequencia (primeiro mostrado para o ultimo)"
    echo " -na >> Representa o NOME do chaincode (Obrigatório)"
    echo " -p >> Representa o PATH do chaincode (Obrigatório)"
    echo " -c >> Representa o NOME DO CANAL do chaincode (Obrigatório)"
    echo " -v >> Representa a VERSÃO do chaincode (Opcional)"
    echo " --private >> Representa que o CHAINCODE vai utilizar PRIVATE DATA, deve apontar para o PATH do arquivo da COLLECTION (Opcional)"
}

function packageChaincode(){
    #$1 - CHAINCODE NAME
    #$2 - CHAINCODE SEQUENCE
    #$3 - CHAINCODE VERSION
    #$4 - CHAINCODE PATH
    #$5 - ORG NAME

    echo "PACKAGING THE CHAINCODE BY ORG $5"
    peer lifecycle chaincode package $1$2.tar.gz \
    --path $4 --lang node --label $1_$3
}

function getVersion(){
    #$1 VERSION (IF EXISTS)

    if [ ! -z $1 ];then
        echo $1
    else
        echo "1.0"
    fi
}

function getSequence(){
    #$1 CHANNEL_ID
    #$2 CHAINCODE NAME
    #$3 CHAINCODE VERSION

    peer lifecycle chaincode querycommitted --channelID $1 \
    --name $2 --cafile ${PWD}/network/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem >&/tmp/sequence.txt
    SEQUENCE=$(cat /tmp/sequence.txt)
    if [[ $SEQUENCE == *"failed"* ]] || [[ $SEQUENCE == *"Error"* ]];then
        SEQUENCE="1"
    else
        SEQUENCE=$(sed -n 2p /tmp/sequence.txt | cut -d ' ' -f4)
        SEQUENCE=${SEQUENCE%?}
        SEQUENCE=$((SEQUENCE+1))
    fi
    echo $SEQUENCE
}

function validateVersion(){
    #$1 SENT VERSION

    OLD_VERSION=$(sed -n 2p /tmp/sequence.txt | cut -d ' ' -f2)
    if [ "$1" = "${OLD_VERSION%?}" ];then
        echo "Para realizar uma ATUALIZAÇÃO enviar uma VERSÃO DIFERENTE"
        echo "CHEQUE a versão utilizando o COMANDO: peer lifecycle chaincode querycommitted <channel-id> --name <chaincode-name> --cafile <cafile-path>"
        exit
    fi
}

function deployChainCode(){
    #$1 - CHAINCODE NAME
    #$2 - PATH OF THE CHAINCODE
    #$3 - CHANNEL
    #$4 - VERSION
    #$5 - PRIVATE DATA CONFIG PATH

    CHAINCODE_NAME=$1
    CHAINCODE_PATH=$2
    CHAINCODE_VERSION=$4
    CHAINCODE_PRIVATE_DATA=$5
    echo "**** VERSION ****"
    echo $CHAINCODE_VERSION

    CHANNEL=$(cat $CONFIG | jq -r ".channels[] | select(.name==\"$3\")")
    CHANNEL_ID=$(echo "$3" | awk '{print tolower($0)}')

    ### CALCULATE TOTAL ORGS ON CONSORT
    TOTAL_ORGS_CONSORT=$(echo $CHANNEL | jq -r '.orgs' | jq length)
    TOTAL_ORGS_CONSORT=$(($TOTAL_ORGS_CONSORT - 1))

    echo $TOTAL_ORGS_CONSORT

    for orgCounter in $(seq 0 $TOTAL_ORGS_CONSORT); do
        ### RECOVER ORG INFO
        ORG=$(echo $CHANNEL | jq -r ".orgs[$orgCounter]")
        ORG_OBJ=$(cat $CONFIG | jq -r ".orgs[] | select(.name==\"${ORG}\")")
        ORG_NAME=$(echo $ORG_OBJ | jq -r '.name')
        ORG_DOMAIN=$(echo $ORG_OBJ | jq -r '.domain')
        ORG_NAME_LOWER=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')
        ORG_HOME=$PWD/network/${ORG_NAME_LOWER}.${ORG_DOMAIN}
        PEER_NAME=$(echo $ORG_OBJ | jq -r '.peer.name')
        PEER_PORT=$(echo $ORG_OBJ | jq -r '.peer.port')

        ### SET TOOLS CONFIG
        export CORE_PEER_LOCALMSPID="${ORG_NAME}MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=${ORG_HOME}/peers/${PEER_NAME}.${ORG_NAME_LOWER}.${ORG_DOMAIN}/tls/ca.crt
        export CORE_PEER_MSPCONFIGPATH=${ORG_HOME}/users/${ORG_NAME_LOWER}admin@${ORG_NAME_LOWER}.${ORG_DOMAIN}/msp
        export CORE_PEER_ADDRESS=localhost:${PEER_PORT}

        ### PACKAGE CHAINCODE IF IS THE FIRST ITERATION
        if [ $orgCounter -eq 0 ];then
            CHAINCODE_VERSION=$(getVersion $CHAINCODE_VERSION)
            SEQUENCE=$(getSequence $CHANNEL_ID $CHAINCODE_NAME $CHAINCODE_VERSION)

            if [ $SEQUENCE -gt "1" ];then
                validateVersion $CHAINCODE_VERSION
            fi            
            
            packageChaincode $CHAINCODE_NAME $SEQUENCE $CHAINCODE_VERSION $CHAINCODE_PATH $ORG_NAME
        fi

        ### INSTALL CHAINCODE
        peer lifecycle chaincode install $CHAINCODE_NAME$SEQUENCE.tar.gz

        ### APROVE CHAINCODE
        echo "APPROVING THE CHAINCODE BY ORG $ORG_NAME"
        PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | grep -i $CHAINCODE_NAME)
        CC_PACKAGE_ID=$(echo $PACKAGE_ID | cut -d ' ' -f3)

        ## SEE IF IT'S PRIVATE OR NOT
        if [ ! -z $CHAINCODE_PRIVATE_DATA ] ;then
            echo "APROVING PRIVATE DATA CHAINCODE DEFINITION"
            peer lifecycle chaincode approveformyorg -o localhost:${ORDERER_PORT} \
            --ordererTLSHostnameOverride ${ORDERER_PEER}.${ORDERER_NAME}.${ORDERER_DOMAIN} \
            --channelID $CHANNEL_ID --name $CHAINCODE_NAME --version ${CHAINCODE_VERSION} \
            --collections-config $CHAINCODE_PRIVATE_DATA --package-id ${CC_PACKAGE_ID%?} --sequence ${SEQUENCE} --tls \
            --cafile $ORDERER_TLS
        else
            echo "APROVING CHAINCODE DEFINITION"
            peer lifecycle chaincode approveformyorg -o localhost:${ORDERER_PORT} \
            --ordererTLSHostnameOverride ${ORDERER_PEER}.${ORDERER_NAME}.${ORDERER_DOMAIN} \
            --channelID $CHANNEL_ID --name $CHAINCODE_NAME --version ${CHAINCODE_VERSION} \
            --package-id ${CC_PACKAGE_ID%?} --sequence ${SEQUENCE} --tls \
            --cafile $ORDERER_TLS 
        fi
        PEERS="${PEERS} --peerAddresses ${CORE_PEER_ADDRESS} --tlsRootCertFiles ${CORE_PEER_TLS_ROOTCERT_FILE}"        
    done
    
    if [ ! -z $CHAINCODE_PRIVATE_DATA ] ;then
        peer lifecycle chaincode commit -o localhost:${ORDERER_PORT} \
        --ordererTLSHostnameOverride ${ORDERER_PEER}.${ORDERER_NAME}.${ORDERER_DOMAIN} \
        --channelID $CHANNEL_ID --name $CHAINCODE_NAME --version $CHAINCODE_VERSION  \
        --collections-config $CHAINCODE_PRIVATE_DATA --sequence ${SEQUENCE} --tls --cafile $ORDERER_TLS \
        $PEERS
    else
         peer lifecycle chaincode commit -o localhost:${ORDERER_PORT} \
        --ordererTLSHostnameOverride ${ORDERER_PEER}.${ORDERER_NAME}.${ORDERER_DOMAIN} \
        --channelID $CHANNEL_ID --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence ${SEQUENCE} \
        --tls --cafile $ORDERER_TLS\
        $PEERS
    fi

}

function checkOpitionalParams(){
    #$1 CHAINCODE VERSION
    #$2 CHAINCODE PRIVATE DATA

    if [ ! -z $1 ] && [ "$1" != "-v" ];then
        echo "Parametro $1 não identificado"
        helpMessage
        exit
    fi
    if [ ! -z $2 ] && [ "$2" != "--private" ];then
        echo "Parametro $2 não identificado"
        helpMessage
        exit
    fi
}

function parseMenu(){
    if [ ! -z $1 ] && [ ! -z $3 ] && [ ! -z $5 ]; then
        if [ "$1" == "-na" ]  && [ "$3" == "-p" ] && [ $5 == "-c" ]; then
            checkOpitionalParams $7 $9
            deployChainCode $2 $4 $6 $8 ${10}
        else
            helpMessage
        fi
    else
        helpMessage
    fi
}

case $1 in
    "--help") helpMessage;;
    *) parseMenu $@;;
esac