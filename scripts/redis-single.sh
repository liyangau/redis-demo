#! /bin/sh

if [ ! "$(docker ps -q -f name=redis-demo)" ]; then
  if [ "$(docker ps -aq -f status=exited -f name=redis-demo)" ]; then
    docker rm redis-demo | 2>/dev/null
    printf "Stopped \033[1;4mredis-demo\033[0m container is removed now. \n"
  fi
  printf "Creating new \033[1;4mredis-demo\033[0m container: \n"
  mkdir -p ./single/conf/
  # sudo rm ./single/conf/redis.conf 2> /dev/null
  cp ./conf/redis.conf ./single/conf/

  if [ ! -z "$2" ] && [ "$2" = "TLS" ]; then
    echo "port 0" >>./single/conf/redis.conf
    echo "tls-port 6379" >>./single/conf/redis.conf
    echo "tls-cert-file /etc/ssl/certs/redis.crt" >>./single/conf/redis.conf
    echo "tls-key-file /etc/ssl/certs/redis.key" >>./single/conf/redis.conf
    echo "tls-dh-params-file /etc/ssl/certs/redis.dh" >>./single/conf/redis.conf
    echo "tls-ca-cert-file /etc/ssl/certs/ca.crt" >>./single/conf/redis.conf
    echo "tls-auth-clients no" >>./single/conf/redis.conf
    echo "tls-protocols \"TLSv1.2 TLSv1.3\"" >>./single/conf/redis.conf

    docker run --name redis-demo \
      --detach --sysctl net.core.somaxconn=511 \
      --volume $(pwd)/single/conf:/etc/redis/ \
      --volume $(pwd)/tls:/etc/ssl/certs \
      --network $1 \
      --publish 6379 \
      redis:7.0-alpine \
      redis-server /etc/redis/redis.conf
  else
    docker run --name redis-demo \
      --detach --sysctl net.core.somaxconn=511 \
      --volume $(pwd)/single/conf:/etc/redis/ \
      --network $1 \
      --publish 6379 \
      redis:7.0-alpine \
      redis-server /etc/redis/redis.conf
  fi
  HOST_IP=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$1\").IPAddress}}" "redis-demo")
  HOST_PORT=$(docker inspect -f "{{ (index (index .NetworkSettings.Ports \"6379/tcp\") 0).HostPort }}" "redis-demo")

  echo "\nRedis demo is running on host IPs and ports at: \033[1;4m${HOST_IP}:${HOST_PORT}\033[0m"
  echo "Redis demo is reachable in docker network $1 at: \033[1;4mredis-demo:6379\033[0m"
else
  echo "\033[1;4mredis-demo\033[0m is already running."
fi