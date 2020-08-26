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
        export readonly BASE_PATH=$(cat $CONFIG | jq -r '.basePath')
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
"bin")
    $PARENTH_PATH/scripts/binaries.sh
    ;;
*)
    echo "Unknow option $TYPE"
    ;;
esac
