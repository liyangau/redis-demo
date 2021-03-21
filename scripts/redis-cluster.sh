#! /bin/sh
numberOfSlave=3

if [ "${1}" -lt 9 ] && [ "${1}" -gt 2 ]; then
    numberOfSlaves=$1
    for i in $(seq 1 $numberOfSlaves)    
    do
        mkdir -p $(PWD)/cluster/conf/$i
        cp $(PWD)/conf/redis.conf $(PWD)/cluster/conf/$i
        echo "slaveof redis-demo 6379 " >>  $(PWD)/cluster/conf/$i/redis.conf
        printf "Creating \033[1;4mredis-$i\033[0m container: \n"
        docker run --name redis-$i \
        --detach --sysctl net.core.somaxconn=511 \
        --volume $(PWD)/cluster/conf/$i/:/etc/redis/ \
        --network $2 \
        redis:6.0-alpine \
        redis-server /etc/redis/redis.conf
    done
else
    echo "We only support creating a redis cluster with 3 to 8 slaves. \n"
    exit
fi