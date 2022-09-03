#  _____          _ _       _____
# |  __ \        | (_)     |  __ \
# | |__) |___  __| |_ ___  | |  | | ___ _ __ ___   ___
# |  _  // _ \/ _` | / __| | |  | |/ _ \ '_ ` _ \ / _ \
# | | \ \  __/ (_| | \__ \ | |__| |  __/ | | | | | (_) |
# |_|  \_\___|\__,_|_|___/ |_____/ \___|_| |_| |_|\___/
#
#
# For more information, please check https://github.com/liyangau/redis-demo
REDIS_6_OFFICIAL_CONF=https://raw.githubusercontent.com/redis/redis/6.0/redis.conf
REDIS_GEN_SSL_SH=https://raw.githubusercontent.com/redis/redis/unstable/utils/gen-test-certs.sh

NETWORK_NAME=redis-demo
REDIS_PASSWORD=A-SUPER-STRONG-DEMO-PASSWORD
REDIS_SSL_CN=redis.test.demo
REDIS_REPLICATION_SLAVES_NUMBER=3
REDIS_CLUSTER_NODES_NUMBER=6
REDIS_SENTINEL_PORT=26379
REDIS_SENTINEL_NUMBER=3

####################################################################################
# Single Redis container creation
####################################################################################
.PHONY: redis-single redis-single-ssl redis/redis.conf

redis-single: redis/redis.conf
	@sh ./scripts/redis-single.sh "$(NETWORK_NAME)"

redis-single-ssl: redis/redis.conf redis-generate-ssl
	@sh ./scripts/redis-single.sh "$(NETWORK_NAME)" "TLS"

redis/redis.conf: redis-check-network
	@mkdir -p ./conf
	@wget --quiet $(REDIS_6_OFFICIAL_CONF) -O ./conf/redis.conf
	@perl -pi -e 's/bind 127.0.0.1/bind 0.0.0.0/g' ./conf/redis.conf
	@echo "requirepass \"$(REDIS_PASSWORD)\"" >>  ./conf/redis.conf
	@echo "masterauth \"$(REDIS_PASSWORD)\"" >>  ./conf/redis.conf
####################################################################################
# Redis Replication Creation
####################################################################################
.PHONY: redis-cluster redis-redis-cluster-ssl
redis-cluster : redis/redis.conf
	@sh ./scripts/redis-cluster.sh "$(REDIS_CLUSTER_NODES_NUMBER)" "$(NETWORK_NAME)" "$(REDIS_PASSWORD)"

redis-cluster-ssl : redis/redis.conf redis-generate-ssl
	@sh ./scripts/redis-cluster.sh "$(REDIS_CLUSTER_NODES_NUMBER)" "$(NETWORK_NAME)" "TLS" "$(REDIS_PASSWORD)"
####################################################################################
# Redis Replication Creation
####################################################################################
.PHONY: redis-replication redis-replication-ssl
redis-replication : redis-single
	@sh ./scripts/redis-replication.sh "$(REDIS_REPLICATION_SLAVES_NUMBER)" "$(NETWORK_NAME)"

redis-replication-ssl : redis-single-ssl
	@sh ./scripts/redis-replication.sh "$(REDIS_REPLICATION_SLAVES_NUMBER)" "$(NETWORK_NAME)" "TLS"
####################################################################################
# Redis Sentinel Creation
####################################################################################
.PHONY: redis-sentinel redis-sentinel-ssl
redis-sentinel : redis-replication
	@sh ./scripts/redis-sentinel.sh "$(REDIS_PASSWORD)" "$(REDIS_SENTINEL_PORT)" "$(NETWORK_NAME)" "$(REDIS_SENTINEL_NUMBER)"

redis-sentinel-ssl : redis-replication-ssl
	@sh ./scripts/redis-sentinel.sh  "$(REDIS_PASSWORD)" "$(REDIS_SENTINEL_PORT)" "$(NETWORK_NAME)" "$(REDIS_SENTINEL_NUMBER)" "TLS"
####################################################################################
# Generate self-sign cert for TLS connection
####################################################################################
.PHONY: redis-generate-ssl
redis-generate-ssl:
	@wget --quiet $(REDIS_GEN_SSL_SH) -O ./gencert.sh
	@perl -pi -e 's/tests\/tls/tls/g' ./gencert.sh
	@perl -i -nle 'print if !/^generate_cert /' ./gencert.sh
	@echo "generate_cert redis \"$(REDIS_SSL_CN)\"" >>  ./gencert.sh
	@echo "chmod -R 755 tls" >>  ./gencert.sh
	@chmod +x gencert.sh
	@sh gencert.sh
####################################################################################
# clean up
####################################################################################
.PHONY: redis-cleanup redis-check-network
redis-cleanup :
	@sh ./scripts/redis-cleanup.sh

redis-check-network :
	@docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || docker network create --driver bridge $(NETWORK_NAME) >/dev/null