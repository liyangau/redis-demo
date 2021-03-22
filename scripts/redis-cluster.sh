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

        if [ ! -z "$3" ] && [ "$3" = "TLS" ]; then
            echo "port 0" >>  $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-port 6379" >>  $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-cert-file /etc/ssl/certs/redis.crt" >>  $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-key-file /etc/ssl/certs/redis.key" >>  $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-dh-params-file /etc/ssl/certs/redis.dh" >>  $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-ca-cert-file /etc/ssl/certs/ca.crt" >>  $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-auth-clients no" >>  $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-protocols \"TLSv1.2 TLSv1.3\"" >>  $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-replication yes" >>  $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-cluster yes" >>  $(PWD)/cluster/conf/$i/redis.conf

            docker run --name redis-$i \
            --detach --sysctl net.core.somaxconn=511 \
            --volume $(PWD)/cluster/conf/$i/:/etc/redis/ \
            --volume $(PWD)/tls:/etc/ssl/certs \
            --network $2 \
            redis:6.0-alpine \
            redis-server /etc/redis/redis.conf
        else
            docker run --name redis-$i \
            --detach --sysctl net.core.somaxconn=511 \
            --volume $(PWD)/cluster/conf/$i/:/etc/redis/ \
            --network $2 \
            redis:6.0-alpine \
            redis-server /etc/redis/redis.conf
        fi
    done
else
    echo "We only support creating a redis cluster with 3 to 8 slaves. \n"
    exit
fi