#!/bin/bash

PEER_NAME=$(echo $ORG | jq -r '.peer.name')
PEER_PORT=$(echo $ORG | jq -r '.peer.port')

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function yaml_ccp {
    local PP=$(one_line_pem $1)
    local CP=$(one_line_pem $2)
    sed -e "s/<ORG_LOWER>/$NAME_LOWER/" \
        -e "s/<ORG>/$NAME/" \
        -e "s/<ORG_DOMAIN>/$DOMAIN/" \
        -e "s/<PEER_NAME>/$PEER_NAME/" \
        -e "s/<PEER_PORT>/$PEER_PORT/" \
        -e "s/<CAPORT>/$PORT/" \
        -e "s#<PEERPEM>#$PP#" \
        -e "s#<CAPEM>#$CP#" \
        ${TEMPLATES}/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

PEERPEM=${ORG_HOME}/tlsca/tlsca.${NAME_LOWER}.${DOMAIN}-cert.pem
CAPEM=${ORG_HOME}/ca/ca.${NAME_LOWER}.${DOMAIN}.pem

echo "$(yaml_ccp $PEERPEM $CAPEM)" > ${ORG_HOME}/connection-org1.yaml
