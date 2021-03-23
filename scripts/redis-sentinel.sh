#! /bin/sh
numberOfSentinel=3

for i in $(seq 1 $numberOfSentinel)    
do
    mkdir -p $(PWD)/sentinel/conf/$i
    rm $(PWD)/sentinel/conf/$i/sentinel.conf 2> /dev/null
    touch $(PWD)/sentinel/conf/$i/sentinel.conf
    echo "port $2" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
    echo "sentinel deny-scripts-reconfig yes" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
    echo "sentinel monitor mymaster redis-demo 6379 2" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
    echo "sentinel down-after-milliseconds mymaster 5000" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
    echo "sentinel failover-timeout mymaster 60000" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
    echo "sentinel parallel-syncs mymaster 1" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
    echo "sentinel auth-pass mymaster $1" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
    printf "Creating \033[1;4mredis-sentinel-$i\033[0m container: \n"

    if [ ! -z "$4" ] && [ "$4" = "TLS" ]; then
        echo "port 0" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
        echo "tls-port 6379" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
        echo "tls-cert-file /etc/ssl/certs/redis.crt" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
        echo "tls-key-file /etc/ssl/certs/redis.key" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
        echo "tls-dh-params-file /etc/ssl/certs/redis.dh" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
        echo "tls-ca-cert-file /etc/ssl/certs/ca.crt" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
        echo "tls-auth-clients no" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
        echo "tls-protocols \"TLSv1.2 TLSv1.3\"" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
        echo "tls-replication yes" >>  $(PWD)/sentinel/conf/$i/sentinel.conf
        echo "tls-cluster yes" >>  $(PWD)/sentinel/conf/$i/sentinel.conf

        docker run --name redis-sentinel-$i \
        --detach --sysctl net.core.somaxconn=511 \
        --volume $(PWD)/sentinel/conf/$i/:/etc/redis/ \
        --volume $(PWD)/tls:/etc/ssl/certs \
        --network $3 \
        redis:6.0-alpine \
        redis-sentinel /etc/redis/sentinel.conf
    else
        docker run --name redis-sentinel-$i \
        --detach --sysctl net.core.somaxconn=511 \
        --volume $(PWD)/sentinel/conf/$i/:/etc/redis/ \
        --network $3 \
        redis:6.0-alpine \
        redis-sentinel /etc/redis/sentinel.conf
    fi
done