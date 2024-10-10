#! /usr/bin/env bash

if [ ! "$(docker ps -q -f name=redis-demo)" ]; then
  if [ "$(docker ps -aq -f status=exited -f name=redis-demo)" ]; then
    docker rm redis-demo | 2>/dev/null
    printf "Stopped redis-demo container is removed now. "
  fi
  printf "Creating new redis-demo container: "
  mkdir -p ./single/conf/
  sudo rm ./single/conf/valkey.conf 2> /dev/null
  cp ./conf/valkey.conf ./single/conf/

  if [ ! -z "$3" ] && [ "$3" = "TLS" ]; then
    echo "port 0" >>./single/conf/valkey.conf
    echo "tls-port 6379" >>./single/conf/valkey.conf
    echo "tls-cert-file /etc/ssl/certs/valkey.crt" >>./single/conf/valkey.conf
    echo "tls-key-file /etc/ssl/certs/valkey.key" >>./single/conf/valkey.conf
    echo "tls-dh-params-file /etc/ssl/certs/valkey.dh" >>./single/conf/valkey.conf
    echo "tls-ca-cert-file /etc/ssl/certs/ca.crt" >>./single/conf/valkey.conf
    echo "tls-auth-clients no" >>./single/conf/valkey.conf
    echo "tls-protocols \"TLSv1.2 TLSv1.3\"" >>./single/conf/valkey.conf

    docker run --name redis-demo \
      --detach --sysctl net.core.somaxconn=511 \
      --volume $(pwd)/single/conf:/etc/valkey/ \
      --volume $(pwd)/tls:/etc/ssl/certs \
      --network $1 \
      --publish 6379 \
      valkey/valkey:$2-alpine \
      valkey-server /etc/valkey/valkey.conf
  else
    docker run --name redis-demo \
      --detach --sysctl net.core.somaxconn=511 \
      --volume $(pwd)/single/conf:/etc/valkey/ \
      --network $1 \
      --publish 6379 \
      valkey/valkey:$2-alpine \
      valkey-server /etc/valkey/valkey.conf
  fi
  HOST_IP=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$1\").IPAddress}}" "redis-demo")
  HOST_PORT=$(docker inspect -f "{{ (index (index .NetworkSettings.Ports \"6379/tcp\") 0).HostPort }}" "redis-demo")

  echo "Redis demo is running on host IPs and ports at: ${HOST_IP}:${HOST_PORT}"
  echo "Redis demo is reachable in docker network $1 at: redis-demo:6379"
else
  echo "redis-demo is already running."
fi