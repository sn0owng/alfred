### SET SCRIPT PATH
export PARENTH_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

### EXPORT BASE VARS
export CONFIG=$1
export BASE_PATH=$(cat $CONFIG | jq -r '.basePath')
export TEMPLATES=${PARENTH_PATH}/template

### EXPORT TOOLS
BIN_PATH=${PARENTH_PATH}/bin
export PATH=${BIN_PATH}:$PATH

### CALCULATE THE NUMBER OF ORGS
TOTAL_ORGS=$(cat $CONFIG| jq -r '.orgs' | jq length)
export TOTAL_ORGS=$(($TOTAL_ORGS-1))

### CREATE CA AND CERTS
for counter in $(seq 0 $TOTAL_ORGS); do
    export ORG=$(cat $CONFIG | jq -r ".orgs[$counter]")
    ${PARENTH_PATH}/scripts/ca/deploy.sh
done

sleep 10

# ### GENERATE NETWORK ARTIFACTS
${PARENTH_PATH}/scripts/network/deploy.sh

sleep 10

### DEPLOY CHAINCODE
${PARENTH_PATH}/scripts/chaincode/deploy.sh