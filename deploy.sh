### EXPORT BASE VARS
export CONFIG=$1
export TEMPLATES=$(cat $CONFIG | jq -r '.templates')
export BASE_PATH=$(cat $CONFIG | jq -r '.basePath')

### EXPORT TOOLS
BIN_PATH=$(cat $CONFIG | jq -r '.binPath')
export PATH=${BIN_PATH}:$PATH

### SET SCRIPT PATH
export PARENTH_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

### CALCULATE THE NUMBER OF ORGS
TOTAL_ORGS=$(cat $CONFIG| jq -r '.orgs' | jq length)
TOTAL_ORGS=$(($TOTAL_ORGS-1))

### CREATE CA AND CERTS
for counter in $(seq 0 $TOTAL_ORGS); do
    export ORG=$(cat $CONFIG | jq -r ".orgs[$counter]")
    ${PARENTH_PATH}/scripts/ca/deploy.sh
done