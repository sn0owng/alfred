### FILL VARS
while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -u )
    USER="$2"
    shift
    ;;
  -p )
    PASSWORD="$2"
    shift
    ;;
  -t )
    TYPE="$2"
    shift
    ;;
  esac
  shift
done

### REGISTER
function register() {
    fabric-ca-client register --caname ca-${NAME_LOWER} --id.name ${USER} --id.secret ${PASSWORD} --id.type ${TYPE} --tls.certfiles ${TLS_CERT}
}

function main() {
  register
}

main