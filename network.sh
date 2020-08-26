### SET SCRIPT PATH
export readonly PARENTH_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
### EXPORT BASE VARS
export readonly TEMPLATES=${PARENTH_PATH}/template
### EXPORT TOOLS
BIN_PATH=${PARENTH_PATH}/bin
export PATH=${BIN_PATH}:$PATH
### SCRIPT CONFIG
set -o errexit 
set -o nounset
### SET OPERATION TYPE
TYPE="$1"
shift
### FILL VARS
while [[ $# -ge 1 ]]; do
    key="$1"
    case $key in
    -c)
        export readonly CONFIG="$2"
        BASE_PATH=$(cat $CONFIG | jq -r '.basePath')
        if [[ "$BASE_PATH" == "" ]]; then
            BASE_PATH=${PARENTH_PATH}/network
        fi
        export readonly BASE_PATH
        shift
        ;;
    esac
    shift
done
### SELECT OPERATION
case $TYPE in
"deploy")
    $PARENTH_PATH/scripts/deploy.sh
    ;;
"cc")
    $PARENTH_PATH/scripts/chaincode/deploy.sh
    ;;
"bin")
    $PARENTH_PATH/scripts/binaries.sh
    ;;
"clean")
    $PARENTH_PATH/scripts/clean.sh
    ;;
*)
    echo "Unknow option $TYPE"
    ;;
esac
