#! /bin/sh
numberOfSentinel=$4

if [ ! "$(docker ps -q -f name=redis-sentinel-1)" ]; then
  for i in $(seq 1 $numberOfSentinel); do
    mkdir -p ./sentinel/conf/$i
    sudo rm ./sentinel/conf/$i/sentinel.conf 2>/dev/null
    touch ./sentinel/conf/$i/sentinel.conf
    echo "port $2" >>./sentinel/conf/$i/sentinel.conf
    echo "sentinel deny-scripts-reconfig yes" >>./sentinel/conf/$i/sentinel.conf
    echo "sentinel resolve-hostnames yes" >>./sentinel/conf/$i/sentinel.conf
    echo "requirepass $1" >>./sentinel/conf/$i/sentinel.conf
    echo "sentinel monitor mymaster redis-demo 6379 2" >>./sentinel/conf/$i/sentinel.conf
    echo "sentinel down-after-milliseconds mymaster 5000" >>./sentinel/conf/$i/sentinel.conf
    echo "sentinel failover-timeout mymaster 60000" >>./sentinel/conf/$i/sentinel.conf
    echo "sentinel parallel-syncs mymaster 1" >>./sentinel/conf/$i/sentinel.conf
    echo "sentinel auth-pass mymaster $1" >>./sentinel/conf/$i/sentinel.conf
    printf "Creating \033[1;4mredis-sentinel-$i\033[0m container: \n"

    if [ ! -z "$5" ] && [ "$5" = "TLS" ]; then
      echo "port 0" >>./sentinel/conf/$i/sentinel.conf
      echo "tls-port $2" >>./sentinel/conf/$i/sentinel.conf
      echo "tls-cert-file /etc/ssl/certs/redis.crt" >>./sentinel/conf/$i/sentinel.conf
      echo "tls-key-file /etc/ssl/certs/redis.key" >>./sentinel/conf/$i/sentinel.conf
      echo "tls-dh-params-file /etc/ssl/certs/redis.dh" >>./sentinel/conf/$i/sentinel.conf
      echo "tls-ca-cert-file /etc/ssl/certs/ca.crt" >>./sentinel/conf/$i/sentinel.conf
      echo "tls-auth-clients no" >>./sentinel/conf/$i/sentinel.conf
      echo "tls-protocols \"TLSv1.2 TLSv1.3\"" >>./sentinel/conf/$i/sentinel.conf
      echo "tls-replication yes" >>./sentinel/conf/$i/sentinel.conf

      docker run --name redis-sentinel-$i \
        --detach --sysctl net.core.somaxconn=511 \
        --volume $(pwd)/sentinel/conf/$i/:/etc/redis/ \
        --volume $(pwd)/tls:/etc/ssl/certs \
        --network $3 \
        --user $UID:$GID \
        --publish $2 \
        redis:7.0-alpine \
        redis-sentinel /etc/redis/sentinel.conf
    else
      docker run --name redis-sentinel-$i \
        --detach --sysctl net.core.somaxconn=511 \
        --volume $(pwd)/sentinel/conf/$i/:/etc/redis/ \
        --network $3 \
        --user $UID:$GID \
        --publish $2 \
        redis:7.0-alpine \
        redis-sentinel /etc/redis/sentinel.conf
    fi
    HOST_IP=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$3\").IPAddress}}" "redis-sentinel-$i")
    HOST_PORT=$(docker inspect -f "{{ (index (index .NetworkSettings.Ports \"$2/tcp\") 0).HostPort }}" "redis-sentinel-$i")
    SENTINEL_ON_HOSTS="${SENTINEL_ON_HOSTS}${HOST_IP}:${HOST_PORT} "
    SENTINEL_IP="$SENTINEL_IP$HOST_IP:$2 "
    SENTINEL_NAMES="$SENTINEL_NAMES"redis-sentinel-"$i:$2 "
  done

  SENTINEL_ON_HOSTS=$(echo $SENTINEL_ON_HOSTS | tr ' ' ',')
  SENTINEL_IP=$(echo $SENTINEL_IP | tr ' ' ',')
  SENTINEL_NAMES=$(echo $SENTINEL_NAMES | tr ' ' ',')
  echo "\nYour sentinel nodes on host IPs and ports are:\n${SENTINEL_ON_HOSTS}"
  echo "\nIn docker network $3, your sentinel nodes hostnames and ports are:\n${SENTINEL_IP}"
  echo "\nIn docker network $3, your sentinel nodes IPs and ports are:\n${SENTINEL_NAMES}"
else
  echo "\033[1;4mredis sentinel\033[0m is already running."
fi