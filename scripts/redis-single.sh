#! /bin/sh
if [ ! "$(docker ps -q -f name=redis-demo)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=redis-demo)" ]; then
        docker rm redis-demo | 2> /dev/null
        printf "Stopped \033[1;4mredis-demo\033[0m container is removed now. \n"
    fi
    printf "Creating new \033[1;4mredis-demo\033[0m container: \n"
    docker run --name redis-demo \
	--detach --sysctl net.core.somaxconn=511 \
    --volume $(PWD)/conf:/etc/redis/ \
    --network $1 \
    redis:6.0-alpine \
    redis-server /etc/redis/redis.conf
else
    echo "redis-demo container is already running."
fi