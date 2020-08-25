### INIT VARS
export ARTIFACTS_PATH=$BASE_PATH/artifacts
export CONFIGTX_PATH=$BASE_PATH/configtx
export FABRIC_CFG_PATH=$CONFIGTX_PATH

### CREATE CONFIGTX
# ${PARENTH_PATH}/scripts/network/configtx.sh

### GENERATE GENESIS BLOCK
# ${PARENTH_PATH}/scripts/network/genesis.sh

### GENERATE COMPOSE FILE AND UP CONTAINERS
# ${PARENTH_PATH}/scripts/network/docker.sh

### GENERATE COMPOSE FILE AND UP CONTAINERS
${PARENTH_PATH}/scripts/network/channel.sh