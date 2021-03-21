#! /bin/sh
if [ "$(docker ps -f name=redis -aq)" ]; then
    docker stop $(docker ps -f name=redis -qa) | 2> /dev/null
    docker rm $(docker ps -f name=redis -qa) | 2> /dev/null
    echo 'Redis containers created had been stoped and removed.'
else
    echo 'Redis containers created by this demo could not be found.'
fi