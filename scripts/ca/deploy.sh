### EXPORT BASE VARS
export NAME=$(echo $ORG | jq -r '.name')
export NAME_LOWER=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
export DOMAIN=$(echo $ORG | jq -r '.domain')
export PORT=$(echo $ORG | jq -r '.ca.port')
export ORG_HOME=${BASE_PATH}/${NAME_LOWER}.${DOMAIN}
export CA_HOME=${ORG_HOME}/cahome
export FABRIC_CA_CLIENT_HOME=${ORG_HOME}
export TLS_CERT=${CA_HOME}/tls-cert.pem

### BASIS ENROLL
function initialEnroll() {
    USER=$(echo $ORG | jq -r ".ca.adminusr")
    PASSWORD=$(echo $ORG | jq -r ".ca.adminpw")
    ${PARENTH_PATH}/scripts/ca/enroll.sh -t basic -u "$USER" -p "$PASSWORD"
}

function registryUser() {
    ${PARENTH_PATH}/scripts/ca/register.sh -u $USERNAME -p $PASSWORD -t $TYPE
}

function enrollUser() {
    ${PARENTH_PATH}/scripts/ca/enroll.sh -u $USERNAME -p $PASSWORD -t $TYPE
}

function createUsers() {
  TOTAL_USERS=$(echo $ORG | jq -r ".users" | jq length)
  TOTAL_USERS=$(($TOTAL_USERS-1))
  for usernum in $(seq 0 $TOTAL_USERS); do
      USER=$(echo $ORG | jq -r ".users[$usernum]")
      USERNAME=$(echo $USER | jq -r ".user")
      PASSWORD=$(echo $USER | jq -r ".password")
      TYPE=$(echo $USER | jq -r ".type")
      registryUser
      enrollUser
  done
}

# ### CREATE FILES AND CONTAINER
# ${PARENTH_PATH}/scripts/ca/files.sh

# sleep 10

# ### DO BASIC ENROLL
# initialEnroll

# ### REGISTER AND ENROLL USERS
# createUsers

### GENERATE CCP
${PARENTH_PATH}/scripts/ca/ccp-generate.sh