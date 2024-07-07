#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
NC="\e[0m"

logSuccess() { echo -e "$GREEN-----$message-----$NC";}
logError() { echo -e "$RED-----$message-----$NC";}
logInfo() { echo -e "$BLUE###############---$message---###############$NC";}

clear
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/home/master/go/bin
message="ko build image" && logInfo
export KO_DOCKER_REPO="ko.local"
ko build ./cmd/activator
if [ "$?" -ne "0" ]; then
    message="ko build error" && logError
    exit 1
else
    message="ko build successfully" && logSuccess
fi

echo -e "\n"
message="change image from docker to crictl" && logInfo
image=$(docker images | grep ko.local | grep latest | awk '{print $1}'):latest
docker rmi -f hctung57/activator:latest
docker image tag $image docker.io/hctung57/activator:latest
docker rmi $image
docker push hctung57/activator:latest
image=$(docker images | grep ko.local | awk '{print $1}'):$(docker images | grep ko.local | awk '{print $2}')
docker rmi $image


echo -e "\n"
message="remove current Pod" && logInfo
pod=$(kubectl -n knative-serving get pod | grep activator | awk '{print $1}')
for i in $pod
do
kubectl -n knative-serving delete pod/$i &
done
# pod=$(kubectl -n knative-serving get pod | grep activator | awk '{print $1}')
# kubectl -n knative-serving logs $pod -f