#! /bin/sh
numberOfNode=6
PASSWORD=''
CLUSTER_ON_HOSTS=''
CLUSTER_HOSTS=''
CLUSTER_NAMES=''

if [ "${1}" -lt 13 ] && [ "${1}" -gt 5 ]; then
  numberOfNodes=$1

  # Create containers
  for i in $(seq 1 ${numberOfNodes}); do
    mkdir -p ./cluster/conf/$i
    sudo rm ./cluster/conf/$i/redis.conf 2> /dev/null
    cp ./conf/redis.conf ./cluster/conf/$i
    echo "cluster-enabled yes" >>./cluster/conf/$i/redis.conf
    echo "cluster-config-file nodes.conf" >>./cluster/conf/$i/redis.conf
    echo "cluster-node-timeout 5000" >>./cluster/conf/$i/redis.conf
    echo "appendonly yes" >>./cluster/conf/$i/redis.conf
    printf "Creating redis-cluster-$i container: "

    if [ ! -z "$4" ] && [ "$4" = "TLS" ]; then
      PASSWORD=$5
      echo "tls-cluster yes" >>./cluster/conf/$i/redis.conf
      echo "tls-replication yes" >>./cluster/conf/$i/redis.conf
      echo "port 0" >>./cluster/conf/$i/redis.conf
      echo "tls-port 6379" >>./cluster/conf/$i/redis.conf
      echo "tls-cert-file /etc/ssl/certs/redis.crt" >>./cluster/conf/$i/redis.conf
      echo "tls-key-file /etc/ssl/certs/redis.key" >>./cluster/conf/$i/redis.conf
      echo "tls-dh-params-file /etc/ssl/certs/redis.dh" >>./cluster/conf/$i/redis.conf
      echo "tls-ca-cert-file /etc/ssl/certs/ca.crt" >>./cluster/conf/$i/redis.conf
      echo "tls-auth-clients no" >>./cluster/conf/$i/redis.conf
      echo "tls-protocols \"TLSv1.2 TLSv1.3\"" >>./cluster/conf/$i/redis.conf

      docker run --name redis-cluster-$i \
        --detach --sysctl net.core.somaxconn=511 \
        --volume $(pwd)/cluster/conf/$i/:/etc/redis/ \
        --volume $(pwd)/tls:/etc/ssl/certs \
        --network $3 \
        --publish 6379 \
        redis:$2-alpine \
        redis-server /etc/redis/redis.conf
    else
      PASSWORD=$4
      docker run --name redis-cluster-$i \
        --detach --sysctl net.core.somaxconn=511 \
        --volume $(pwd)/cluster/conf/$i/:/etc/redis/ \
        --network $3 \
        --publish 6379 \
        redis:$2-alpine \
        redis-server /etc/redis/redis.conf
    fi
    HOST_IP=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$3\").IPAddress}}" "redis-cluster-$i")
    HOST_PORT=$(docker inspect -f "{{ (index (index .NetworkSettings.Ports \"6379/tcp\") 0).HostPort }}" "redis-cluster-$i")
    CLUSTER_ON_HOSTS="${CLUSTER_ON_HOSTS}${HOST_IP}:${HOST_PORT} "
    CLUSTER_HOSTS="${CLUSTER_HOSTS}${HOST_IP}:6379 "
    CLUSTER_NAMES="${CLUSTER_NAMES}"redis-cluster-"$i:6379 "
  done

  # Create cluster
  if [ ! -z "$4" ] && [ "$4" = "TLS" ]; then
    docker run -i --rm \
      --volume $(pwd)/cluster/conf/1/:/etc/redis/ \
      --volume $(pwd)/tls:/etc/ssl/certs \
      --network $3 \
      redis:$2-alpine \
      redis-cli --tls \
      --cert /etc/ssl/certs/redis.crt \
      --key /etc/ssl/certs/redis.key \
      --cacert /etc/ssl/certs/ca.crt \
      -a $5 --cluster create $CLUSTER_HOSTS --cluster-yes --cluster-replicas 1
  else
    docker run -i --rm \
      --net $3 \
      redis:$2-alpine \
      redis-cli --no-auth-warning -a $4 --cluster create ${CLUSTER_HOSTS} --cluster-yes --cluster-replicas 1
  fi
  CLUSTER_ON_HOSTS=$(echo ${CLUSTER_ON_HOSTS} | tr ' ' ',')
  CLUSTER_HOSTS=$(echo ${CLUSTER_HOSTS} | tr ' ' ',')
  CLUSTER_NAMES=$(echo ${CLUSTER_NAMES} | tr ' ' ',')
  echo "Your cluster nodes on host IPs and ports are:${CLUSTER_ON_HOSTS}"
  echo "In docker network $3, your cluster nodes IPs and ports are:${CLUSTER_HOSTS}"
  echo "In docker network $3, your cluster nodes hostnames and ports are:${CLUSTER_NAMES}"
else
  echo "We only support creating a redis cluster with 6 to 12 nodes."
  exit
fi
