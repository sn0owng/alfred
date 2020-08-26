### CALCULATE THE NUMBER OF ORGS
TOTAL_ORGS=$(cat $CONFIG| jq -r '.orgs' | jq length)
export TOTAL_ORGS=$(($TOTAL_ORGS-1))

### CREATE CA AND CERTS
for counter in $(seq 0 $TOTAL_ORGS); do
    export ORG=$(cat $CONFIG | jq -r ".orgs[$counter]")
    ${PARENTH_PATH}/scripts/ca/deploy.sh
done

# sleep 10

# # ### GENERATE NETWORK ARTIFACTS
# ${PARENTH_PATH}/scripts/network/deploy.sh

# sleep 10

# ### DEPLOY CHAINCODE
# ${PARENTH_PATH}/scripts/chaincode/deploy.sh