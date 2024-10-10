#  ____   ____      __   __                       ______                               
# |_  _| |_  _|    [  | [  |  _                  |_   _ `.                             
#   \ \   / /,--.   | |  | | / ] .---.   _   __    | | `. \ .---.  _ .--..--.   .--.   
#    \ \ / /`'_\ :  | |  | '' < / /__\\ [ \ [  ]   | |  | |/ /__\\[ `.-. .-. |/ .'`\ \ 
#     \ ' / // | |, | |  | |`\ \| \__.,  \ '/ /   _| |_.' /| \__., | | | | | || \__. | 
#      \_/  \'-;__/[___][__|  \_]'.__.'[\_:  /   |______.'  '.__.'[___||__||__]'.__.'  
#                                       \__.'                                          
# For more information, please check https://github.com/liyangau/redis-demo
VALKEY_VERSION=8.0
VALKEY_OFFICIAL_CONF=https://raw.githubusercontent.com/valkey-io/valkey/$(VALKEY_VERSION)/valkey.conf
VALKEY_GEN_SSL_SH=https://raw.githubusercontent.com/valkey-io/valkey/unstable/utils/gen-test-certs.sh

NETWORK_NAME=redis-demo
VALKEY_PASSWORD=A-SUPER-STRONG-DEMO-PASSWORD
VALKEY_SSL_CN=redis.test.demo
VALKEY_REPLICATION_SLAVES_NUMBER=3
VALKEY_CLUSTER_NODES_NUMBER=6
VALKEY_SENTINEL_PORT=26379
VALKEY_SENTINEL_NUMBER=3

####################################################################################
# Single Valkey container creation
####################################################################################
.PHONY: redis-single redis-single-ssl redis/redis.conf

redis-single: redis/redis.conf
	@sh ./scripts/valkey-single.sh "$(NETWORK_NAME)" "$(VALKEY_VERSION)"

redis-single-ssl: redis/redis.conf redis-generate-ssl
	@sh ./scripts/valkey-single.sh "$(NETWORK_NAME)" "$(VALKEY_VERSION)" "TLS"

redis/redis.conf: redis-check-network
	@mkdir -p ./conf
	@wget --quiet $(VALKEY_OFFICIAL_CONF) -O ./conf/valkey.conf
	@perl -pi -e 's/bind 127.0.0.1/bind 0.0.0.0/g' ./conf/valkey.conf
	@echo "requirepass \"$(VALKEY_PASSWORD)\"" >>  ./conf/valkey.conf
	@echo "masterauth \"$(VALKEY_PASSWORD)\"" >>  ./conf/valkey.conf
####################################################################################
# Valkey Cluster Creation
####################################################################################
.PHONY: redis-cluster redis-redis-cluster-ssl
redis-cluster : redis/redis.conf
	@sh ./scripts/valkey-cluster.sh "$(VALKEY_CLUSTER_NODES_NUMBER)" "$(VALKEY_VERSION)" "$(NETWORK_NAME)" "$(VALKEY_PASSWORD)"

redis-cluster-ssl : redis/redis.conf redis-generate-ssl
	@sh ./scripts/valkey-cluster.sh "$(VALKEY_CLUSTER_NODES_NUMBER)" "$(VALKEY_VERSION)" "$(NETWORK_NAME)" "TLS" "$(VALKEY_PASSWORD)"
####################################################################################
# Valkey Replication Creation
####################################################################################
.PHONY: redis-replication redis-replication-ssl
redis-replication : redis-single
	@sh ./scripts/valkey-replication.sh "$(VALKEY_REPLICATION_SLAVES_NUMBER)" "$(VALKEY_VERSION)" "$(NETWORK_NAME)"

redis-replication-ssl : redis-single-ssl
	@sh ./scripts/valkey-replication.sh "$(VALKEY_REPLICATION_SLAVES_NUMBER)" "$(VALKEY_VERSION)" "$(NETWORK_NAME)" "TLS"
####################################################################################
# Valkey Sentinel Creation
####################################################################################
.PHONY: redis-sentinel redis-sentinel-ssl
redis-sentinel : redis-replication
	@sh ./scripts/valkey-sentinel.sh "$(VALKEY_PASSWORD)" "$(VALKEY_VERSION)" "$(VALKEY_SENTINEL_PORT)" "$(NETWORK_NAME)" "$(VALKEY_SENTINEL_NUMBER)"

redis-sentinel-ssl : redis-replication-ssl
	@sh ./scripts/valkey-sentinel.sh  "$(VALKEY_PASSWORD)" "$(VALKEY_VERSION)" "$(VALKEY_SENTINEL_PORT)" "$(NETWORK_NAME)" "$(VALKEY_SENTINEL_NUMBER)" "TLS"
####################################################################################
# Generate self-sign cert for TLS connection
####################################################################################
.PHONY: redis-generate-ssl
redis-generate-ssl:
	@wget --quiet $(VALKEY_GEN_SSL_SH) -O ./gencert.sh
	@perl -pi -e 's/tests\/tls/tls/g' ./gencert.sh
	@perl -i -nle 'print if !/^generate_cert /' ./gencert.sh
	@echo "generate_cert valkey \"$(VALKEY_SSL_CN)\"" >>  ./gencert.sh
	@echo "chmod -R 755 tls" >>  ./gencert.sh
	@chmod +x gencert.sh
	@sh gencert.sh
####################################################################################
# clean up
####################################################################################
.PHONY: redis-cleanup valkey-check-network
redis-cleanup :
	@sh ./scripts/valkey-cleanup.sh

redis-check-network :
	@docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || docker network create --driver bridge $(NETWORK_NAME) >/dev/null
