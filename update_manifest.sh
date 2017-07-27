DOCKER_USERNAME=$1
DOCKER_PASSWORD=$2

MANIFEST_TOOL_URL=https://github.com/estesp/manifest-tool/releases/download/v0.4.0/manifest-tool-linux-amd64

wget $MANIFEST_TOOL_URL
chmod 755 ./manifest-tool-linux-amd64

docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"

./manifest-tool-linux-amd64 push from-spec ./manifest-jessie.yml

