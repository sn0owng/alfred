### DEFINE BASE VARS
NAME=$(echo $ORG | jq -r '.name')
CA_PORT=$(echo $ORG | jq -r '.ca.port')
NAME_LOWER=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')
ORG_HOME=${BASE_PATH}/${ORG_LOWER}.${DOMAIN}
CA_HOME=${ORG_HOME}/cahome
DOCKER_HOME=${ORG_HOME}/docker
COMPOSE=${DOCKER_HOME}/fabric-ca.yaml

### CREATE CA FOLDERS
mkdir -p $CA_HOME
mkdir -p $DOCKER_HOME

### CREATE CA CONFIG
function ca() {
   ### COPY TEMPLATE
   cp $TEMPLATES/fabric-ca-template.yaml $CA_HOME/fabric-ca-server-config.yaml
   ### CHANGE TEMPLATE VALUES
   sed -i "s/<CA_PORT>/$CA_PORT/" $CA_HOME/fabric-ca-server-config.yaml
   sed -i -e "0,/<ORG_NAME>/ s/<ORG_NAME>/$NAME/" $CA_HOME/fabric-ca-server-config.yaml
   sed -i -e "0,/<ORG_NAME>/ s/<ORG_NAME>/$NAME_LOWER/" $CA_HOME/fabric-ca-server-config.yaml
   sed -i -e "0,/<ORG_NAME>/ s/<ORG_NAME>/$NAME_LOWER/" $CA_HOME/fabric-ca-server-config.yaml
   sed -i -e "0,/<ORG_NAME>/ s/<ORG_NAME>/$NAME_LOWER/" $CA_HOME/fabric-ca-server-config.yaml
   sed -i "s/<ORG_DOMAIN>/$DOMAIN/" $CA_HOME/fabric-ca-server-config.yaml
}

function compose() {
  cp $TEMPLATES/fabric-ca-compose-template.yaml $COMPOSE
  sed -i "s/<CA_PORT>/$PORT/" $COMPOSE
  sed -i "s/<CA_PORT>/$PORT/" $COMPOSE
  sed -i "s/<ORG_NAME>/$NAME_LOWER/" $COMPOSE
  sed -i "s,<CA_FOLDER>,$CA_HOME," $COMPOSE
}
