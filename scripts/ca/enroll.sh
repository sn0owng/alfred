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

### ENROLL ORG
function basicEnroll() {
  fabric-ca-client enroll -u https://${USER}:${PASSWORD}@localhost:${PORT} --caname ca-${NAME_LOWER} --tls.certfiles ${TLS_CERT}
}

### ENROLL USER
function enrollUser() {
  USER_FOLDER=${FABRIC_CA_CLIENT_HOME}/users/${USER}@${NAME_LOWER}.${DOMAIN}
  mkdir -p $USER_FOLDER
  fabric-ca-client enroll -u https://${USER}:${PASSWORD}@localhost:${PORT} --caname ca-${NAME_LOWER} -M ${USER_FOLDER}/msp --tls.certfiles ${TLS_CERT}
  cp ${FABRIC_CA_CLIENT_HOME}/msp/config.yaml $USER_FOLDER/msp/config.yaml
}

### ENROLL PEER
function enrollPeer() {
  PEER_FOLDER=${FABRIC_CA_CLIENT_HOME}/peers/${USER}.${NAME_LOWER}.${DOMAIN}

  mkdir -p $PEER_FOLDER

  fabric-ca-client enroll -u https://${USER}:${PASSWORD}@localhost:${PORT} --caname ca-${NAME_LOWER} -M ${PEER_FOLDER}/msp --csr.hosts ${USER}.${NAME_LOWER}.${DOMAIN} --csr.hosts localhost --tls.certfiles ${TLS_CERT}

  cp ${FABRIC_CA_CLIENT_HOME}/msp/config.yaml $PEER_FOLDER/msp/config.yaml

  fabric-ca-client enroll -u https://${USER}:${PASSWORD}@localhost:${PORT} --caname ca-${NAME_LOWER} -M ${PEER_FOLDER}/tls --enrollment.profile tls --csr.hosts ${USER}.${NAME_LOWER}.${DOMAIN} --csr.hosts localhost --tls.certfiles ${TLS_CERT}
  
  organizeCerts
}

### ORGANIZE CERTS
function organizeCerts() {
  cp ${PEER_FOLDER}/tls/tlscacerts/* ${PEER_FOLDER}/tls/ca.crt
  cp ${PEER_FOLDER}/tls/signcerts/* ${PEER_FOLDER}/tls/server.crt
  cp ${PEER_FOLDER}/tls/keystore/* ${PEER_FOLDER}/tls/server.key

  mkdir -p ${FABRIC_CA_CLIENT_HOME}/msp/tlscacerts
  cp ${PEER_FOLDER}/tls/tlscacerts/* ${FABRIC_CA_CLIENT_HOME}/msp/tlscacerts/ca.crt

  mkdir -p ${FABRIC_CA_CLIENT_HOME}/tlsca
  cp ${PEER_FOLDER}/tls/tlscacerts/* ${FABRIC_CA_CLIENT_HOME}/tlsca/tlsca.${NAME_LOWER}.${DOMAIN}-cert.pem

  mkdir -p ${FABRIC_CA_CLIENT_HOME}/ca
  cp ${PEER_FOLDER}/msp/cacerts/* ${FABRIC_CA_CLIENT_HOME}/ca/ca.${NAME_LOWER}.${DOMAIN}.pem
}

function plotConfig() {
  echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG_LOWER}.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG_LOWER}.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG_LOWER}.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG_LOWER}.pem
    OrganizationalUnitIdentifier: orderer" > ${FABRIC_CA_CLIENT_HOME}/msp/config.yaml
}

function main() {
  if [[ "$TYPE" == "basic" ]]; then
    basicEnroll
    plotConfig
  elif [[ "$TYPE" == "client" || "$TYPE" == "admin" ]]; then
    enrollUser
  elif [[ "$TYPE" == "peer" || "$TYPE" == "orderer" ]]; then
    enrollPeer
  fi
}

main