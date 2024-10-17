#! /usr/bin/env bash

numberOfSlave=3

if [ ! "$(docker ps -q -f name=valkey-1)" ]; then
  if [ "${1}" -lt 9 ] && [ "${1}" -gt 0 ]; then
    numberOfSlaves=$1
    echo ""
    for i in $(seq 1 $numberOfSlaves); do
      mkdir -p ./replication/conf/$i
      sudo rm ./replication/conf/$i/valkey.conf 2> /dev/null
      cp ./conf/valkey.conf ./replication/conf/$i
      echo "slaveof redis-demo 6379" >>./replication/conf/$i/valkey.conf
      printf "Creating replicate redis-$i container: "
      if [ ! -z "$4" ] && [ "$4" = "TLS" ]; then
        echo "tls-replication yes" >>./replication/conf/$i/valkey.conf
        echo "port 0" >>./replication/conf/$i/valkey.conf
        echo "tls-port 6379" >>./replication/conf/$i/valkey.conf
        echo "tls-cert-file /etc/ssl/certs/valkey.crt" >>./replication/conf/$i/valkey.conf
        echo "tls-key-file /etc/ssl/certs/valkey.key" >>./replication/conf/$i/valkey.conf
        echo "tls-dh-params-file /etc/ssl/certs/valkey.dh" >>./replication/conf/$i/valkey.conf
        echo "tls-ca-cert-file /etc/ssl/certs/ca.crt" >>./replication/conf/$i/valkey.conf
        echo "tls-auth-clients no" >>./replication/conf/$i/valkey.conf
        echo "tls-protocols \"TLSv1.2 TLSv1.3\"" >>./replication/conf/$i/valkey.conf

        docker run --name redis-$i \
          --detach --sysctl net.core.somaxconn=511 \
          --volume $(pwd)/replication/conf/$i/:/etc/valkey/ \
          --volume $(pwd)/tls:/etc/ssl/certs \
          --network $3 \
          --publish 6379 \
          valkey/valkey:$2-alpine \
          valkey-server /etc/valkey/valkey.conf
      else
        docker run --name redis-$i \
          --detach --sysctl net.core.somaxconn=511 \
          --volume $(pwd)/replication/conf/$i/:/etc/valkey/ \
          --network $3 \
          --publish 6379 \
          valkey/valkey:$2-alpine \
          valkey-server /etc/valkey/valkey.conf
      fi
      HOST_IP=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$3\").IPAddress}}" "redis-$i")
      HOST_PORT=$(docker inspect -f "{{ (index (index .NetworkSettings.Ports \"6379/tcp\") 0).HostPort }}" "redis-$i")
      CLUSTER_ON_HOSTS="${CLUSTER_ON_HOSTS}${HOST_IP}:${HOST_PORT} "
      CLUSTER_HOSTS="${CLUSTER_HOSTS}${HOST_IP}:6379 "
      CLUSTER_NAMES="${CLUSTER_NAMES}"valkey-"$i:6379 "
    done

    CLUSTER_ON_HOSTS=$(echo ${CLUSTER_ON_HOSTS} | tr ' ' ',')
    CLUSTER_HOSTS=$(echo ${CLUSTER_HOSTS} | tr ' ' ',')
    CLUSTER_NAMES=$(echo ${CLUSTER_NAMES} | tr ' ' ',')
    echo "Your replicate nodes on host IPs and ports are:${CLUSTER_ON_HOSTS}"
    echo "In docker network $3, your replicate nodes hostnames and ports are:${CLUSTER_NAMES}"
    echo "In docker network $3, your replicate nodes IPs and ports are:${CLUSTER_HOSTS}"
  else
    docker stop redis-demo | 2>/dev/null
    docker rm redis-demo | 2>/dev/null
    echo "We only support creating a valkey replication with 1 to 8 slaves."
    echo "Removing redis-demo container. "
    exit
  fi
else
  echo "valkey replication is already running."
fi