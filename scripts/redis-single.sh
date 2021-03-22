#! /bin/sh

if [ ! "$(docker ps -q -f name=redis-demo)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=redis-demo)" ]; then
        docker rm redis-demo | 2> /dev/null
        printf "Stopped \033[1;4mredis-demo\033[0m container is removed now. \n"
    fi
    printf "Creating new \033[1;4mredis-demo\033[0m container: \n"
    if [ ! -z "$2" ] && [ "$2" = "TLS" ]; then
        echo "port 0" >> $(PWD)/conf/redis.conf
        echo "tls-port 6379" >> $(PWD)/conf/redis.conf
        echo "tls-cert-file /etc/ssl/certs/redis.crt" >> $(PWD)/conf/redis.conf
        echo "tls-key-file /etc/ssl/certs/redis.key" >> $(PWD)/conf/redis.conf
        echo "tls-dh-params-file /etc/ssl/certs/redis.dh" >> $(PWD)/conf/redis.conf
        echo "tls-ca-cert-file /etc/ssl/certs/ca.crt" >> $(PWD)/conf/redis.conf
        echo "tls-auth-clients no" >> $(PWD)/conf/redis.conf
        echo "tls-protocols \"TLSv1.2 TLSv1.3\"" >> $(PWD)/conf/redis.conf

        docker run --name redis-demo \
        --detach --sysctl net.core.somaxconn=511 \
        --volume $(PWD)/conf:/etc/redis/ \
        --volume $(PWD)/tls:/etc/ssl/certs \
        --network $1 \
        redis:6.0-alpine \
        redis-server /etc/redis/redis.conf
    else
        docker run --name redis-demo \
        --detach --sysctl net.core.somaxconn=511 \
        --volume $(PWD)/conf:/etc/redis/ \
        --network $1 \
        redis:6.0-alpine \
        redis-server /etc/redis/redis.conf
    fi
else
    echo "redis-demo container is already running."
fi