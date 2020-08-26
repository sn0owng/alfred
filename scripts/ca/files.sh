### DEFINE BASE VARS
CONFIG_FILE=${CA_HOME}/fabric-ca-server-config.yaml
DOCKER_HOME=${ORG_HOME}/docker
COMPOSE=${DOCKER_HOME}/fabric-ca.yaml

### CREATE CA FOLDERS
mkdir -p $CA_HOME
mkdir -p $DOCKER_HOME

### CREATE CA CONFIG
function config() {
   ### COPY TEMPLATE
   cp $TEMPLATES/fabric-ca-template.yaml $CONFIG_FILE
   ### CHANGE TEMPLATE VALUES
   sed -i'' "s/<CA_PORT>/$CA_PORT/" $CONFIG_FILE
   sed -i'' -e "0,/<ORG_NAME>/ s/<ORG_NAME>/$NAME/" $CONFIG_FILE
   sed -i'' "s/<ORG_NAME>/$NAME_LOWER/" $CONFIG_FILE
   sed -i'' "s/<ORG_DOMAIN>/$DOMAIN/" $CONFIG_FILE
}

function compose() {
  ### COPY TEMPLATE
  cp $TEMPLATES/fabric-ca-compose-template.yaml $COMPOSE
  ### CHANGE TEMPLATE VALUES
  sed -i'' "s/<CA_PORT>/$PORT/" $COMPOSE
  sed -i'' "s/<CA_PORT>/$PORT/" $COMPOSE
  sed -i'' "s/<ORG_NAME>/$NAME_LOWER/" $COMPOSE
  sed -i'' "s,<CA_FOLDER>,$CA_HOME," $COMPOSE
}

function up() {
  docker-compose -f $COMPOSE up -d
}

config
compose
up