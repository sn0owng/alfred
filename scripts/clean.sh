### DELETE ALL CONTAINERS
docker rm -f $(docker ps -q -a)

### DELETE FOLDER
sudo rm -rf "$BASE_PATH"