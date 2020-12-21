#!/bin/bash


CONCOURSE_DOCKER_COMPOSE="https://concourse-ci.org/docker-compose.yml"
PUBLIC_HOSTNAME_URL="http://169.254.169.254/latest/meta-data/public-hostname"
REQUIRED_PKGS="wget docker curl"
DOCKER_COMPOSE_CMD="/usr/local/bin/docker-compose"
FLY_CMD="/usr/local/bin/fly"
LOGFILE="/dev/null"
FLY_VERSION="6.7.2"
CLI="https://github.com/concourse/concourse/releases/download/v${FLY_VERSION}/fly-${FLY_VERSION}-linux-amd64.tgz"
PIPELINE="pipeline_hello_world.yml"


echo "Checking pre-requisite..."
for pkg in ${REQUIRED_PKGS}
do
	which ${pkg} >/dev/null 2>&1
	if [ $? -ne 0 ];then
		echo "Package - ${pkg} is not installed"
		exit 1
	fi
done

echo "Downloading docker-compose file"
wget ${CONCOURSE_DOCKER_COMPOSE} >>${LOGFILE} 2>&1
if [ $? -ne 0 ];then
	echo "Failed to Download docker-compose file for concourse"
	exit 1
fi

HOSTURL=$(curl -s ${PUBLIC_HOSTNAME_URL})
if [ -z "${HOSTURL}" ];then
	echo "Failed to fetch host URL details"
	exit 1
fi
sed -i "s/.*CONCOURSE_EXTERNAL_URL.*/      CONCOURSE_EXTERNAL_URL: http:\/\/${HOSTURL}:8080/" docker-compose.yml
echo "Running concouse using docker compose"
#${DOCKER_COMPOSE_CMD} up -d # You can modify this based on your need.
sudo ${DOCKER_COMPOSE_CMD} up -d # You can modify this based on your need.
if [ $? -ne 0 ];then
	echo "Faield run docker-compose"
	exit 1
fi
echo "Downloading concourse CLI fly"
wget ${CLI} >>${LOGFILE} 2>&1
if [ $? -ne 0 ];then
	echo "Failed to download fly"
	exit 1
fi
sudo tar xvf fly-${FLY_VERSION}-linux-amd64.tgz -C /usr/local/bin/
sudo chmod +x ${FLY_CMD}
if [ ! -f "${PIPELINE}" ];then
	echo "Pipeline file not present"
	exit 1
fi
echo "Login and setup for consourse"
sleep 5
sudo ${FLY_CMD} -t tutorial login -c http://localhost:8080 -u test -p test # If you want to change the credentials, change in docker-compose file
echo "y" | sudo ${FLY_CMD} -t tutorial sp -p hellow-world -c ${PIPELINE}
sudo ${FLY_CMD} -t tutorial unpause-pipeline -p hellow-world
echo "You can access your consourse URL using http://${HOSTURL}:8080"
