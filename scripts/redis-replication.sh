#! /bin/sh
numberOfSlave=3

if [ "${1}" -lt 9 ] && [ "${1}" -gt 0 ]; then
    numberOfSlaves=$1
    
    for i in $(seq 1 $numberOfSlaves)    
    do
        mkdir -p ./replication/conf/$i
        cp ./conf/redis.conf ./replication/conf/$i
        echo "slaveof redis-demo 6379 " >>  ./replication/conf/$i/redis.conf
        printf "Creating \033[1;4mredis-$i\033[0m container: \n"     

        if [ ! -z "$3" ] && [ "$3" = "TLS" ]; then
            echo "tls-replication yes" >>  ./replication/conf/$i/redis.conf
            echo "port 0" >> ./replication/conf/$i/redis.conf
            echo "tls-port 6379" >> ./replication/conf/$i/redis.conf
            echo "tls-cert-file /etc/ssl/certs/redis.crt" >> ./replication/conf/$i/redis.conf
            echo "tls-key-file /etc/ssl/certs/redis.key" >> ./replication/conf/$i/redis.conf
            echo "tls-dh-params-file /etc/ssl/certs/redis.dh" >> ./replication/conf/$i/redis.conf
            echo "tls-ca-cert-file /etc/ssl/certs/ca.crt" >> ./replication/conf/$i/redis.conf
            echo "tls-auth-clients no" >> ./replication/conf/$i/redis.conf
            echo "tls-protocols \"TLSv1.2 TLSv1.3\"" >> ./replication/conf/$i/redis.conf

            docker run --name redis-$i \
            --detach --sysctl net.core.somaxconn=511 \
            --volume $(pwd)/replication/conf/$i/:/etc/redis/ \
            --volume $(pwd)/tls:/etc/ssl/certs \
            --network $2 \
            redis:6.0-alpine \
            redis-server /etc/redis/redis.conf
        else
            docker run --name redis-$i \
            --detach --sysctl net.core.somaxconn=511 \
            --volume $(pwd)/replication/conf/$i/:/etc/redis/ \
            --network $2 \
            redis:6.0-alpine \
            redis-server /etc/redis/redis.conf
        fi
    done
else
    docker stop redis-demo | 2> /dev/null
    docker rm redis-demo | 2> /dev/null
    echo "\nWe only support creating a redis replication with 1 to 8 slaves."
    echo "Removing \033[1;4mredis-demo\033[0m container. \n"
    exit
fi