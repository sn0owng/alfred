### GENERATE GENESIS BLOCK
GENESIS_NAME=$(cat $CONFIG | jq -r '.genesis.name')
GENESIS_OUTPUT=$ARTIFACTS_PATH/genesis/system-genesis.block
configtxgen -profile $GENESIS_NAME -channelID system-channel -outputBlock $GENESIS_OUTPUT -configPath $CONFIGTX_PATH