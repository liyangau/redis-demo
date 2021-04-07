#! /bin/sh
numberOfNode=6
PASSWORD=''
CLUSTER_HOSTS=''
CLUSTER_NAMES=''

if [ "${1}" -lt 13 ] && [ "${1}" -gt 5 ]; then
    numberOfNodes=$1
    
    for i in $(seq 1 $numberOfNodes)    
    do
        mkdir -p $(PWD)/cluster/conf/$i
        cp $(PWD)/conf/redis.conf $(PWD)/cluster/conf/$i
        echo "cluster-enabled yes" >> $(PWD)/cluster/conf/$i/redis.conf
        echo "cluster-config-file nodes.conf" >> $(PWD)/cluster/conf/$i/redis.conf
        echo "cluster-node-timeout 5000" >> $(PWD)/cluster/conf/$i/redis.conf
        echo "appendonly yes" >> $(PWD)/cluster/conf/$i/redis.conf
        printf "Creating \033[1;4mredis-cluster-$i\033[0m container: \n"
        
        if [ ! -z "$3" ] && [ "$3" = "TLS" ]; then
            PASSWORD=$4
            echo "tls-cluster yes" >>  $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-replication yes" >>  $(PWD)/cluster/conf/$i/redis.conf
            echo "port 0" >> $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-port 6379" >> $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-cert-file /etc/ssl/certs/redis.crt" >> $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-key-file /etc/ssl/certs/redis.key" >> $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-dh-params-file /etc/ssl/certs/redis.dh" >> $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-ca-cert-file /etc/ssl/certs/ca.crt" >> $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-auth-clients no" >> $(PWD)/cluster/conf/$i/redis.conf
            echo "tls-protocols \"TLSv1.2 TLSv1.3\"" >> $(PWD)/cluster/conf/$i/redis.conf

            docker run --name redis-cluster-$i \
            --detach --sysctl net.core.somaxconn=511 \
            --volume $(PWD)/cluster/conf/$i/:/etc/redis/ \
            --volume $(PWD)/tls:/etc/ssl/certs \
            --network $2 \
            redis:6.0-alpine \
            redis-server /etc/redis/redis.conf
        else
            PASSWORD=$3
            docker run --name redis-cluster-$i \
            --detach --sysctl net.core.somaxconn=511 \
            --volume $(PWD)/cluster/conf/$i/:/etc/redis/ \
            --network $2 \
            redis:6.0-alpine \
            redis-server /etc/redis/redis.conf
        fi
    done
    
    for id in `seq 1 $numberOfNode`; do 
        HOST_IP=`docker inspect -f "{{(index .NetworkSettings.Networks \"$2\").IPAddress}}" "redis-cluster-"$id`; 
        CLUSTER_HOSTS="$CLUSTER_HOSTS$HOST_IP:6379 "; 
        CLUSTER_NAMES="$CLUSTER_NAMES"redis-cluster-"$id:6379 "; 
    done
    

    if [ ! -z "$3" ] && [ "$3" = "TLS" ]; then
        docker run -i --rm \
        --volume $(PWD)/cluster/conf/1/:/etc/redis/ \
        --volume $(PWD)/tls:/etc/ssl/certs \
        --network $2 \
        redis:6.0-alpine \
        redis-cli --tls \
        --cert /etc/ssl/certs/redis.crt \
        --key /etc/ssl/certs/redis.key \
        --cacert /etc/ssl/certs/ca.crt \
        -a $4 --cluster create $CLUSTER_HOSTS --cluster-yes --cluster-replicas 1;
    else
        docker run -i --rm --net $2 redis:6.0-alpine \
            redis-cli --no-auth-warning -a $3 --cluster create $CLUSTER_HOSTS --cluster-yes --cluster-replicas 1;        
    fi

    CLUSTER_HOSTS=${CLUSTER_HOSTS// /,}
    CLUSTER_NAMES=${CLUSTER_NAMES// /,}
    echo "Your cluster host IPs are:" ${CLUSTER_HOSTS%?}
    echo "Your cluster hostnames are:" ${CLUSTER_NAMES%?}
else
    echo "\nWe only support creating a redis cluster with 6 to 12 nodes."
    exit
fi