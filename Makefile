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
REDIS_CLUSTER_SLAVES_NUMBER=3
REDIS_SENTINEL_PORT=5000

####################################################################################
# Single Redis container creation
####################################################################################
.PHONY: redis-single redis-single-ssl redis/redis.conf 

redis-single: redis/redis.conf
	@sh $(PWD)/scripts/redis-single.sh "$(NETWORK_NAME)"

redis-single-ssl: redis/redis.conf redis-generate-ssl
	@sh $(PWD)/scripts/redis-single.sh "$(NETWORK_NAME)" "TLS"
	
redis/redis.conf:
	@mkdir -p $(PWD)/conf
	@wget --quiet $(REDIS_6_OFFICIAL_CONF) -O $(PWD)/conf/redis.conf
	@sed -i '' 's/bind 127.0.0.1/bind 0.0.0.0/g' $(PWD)/conf/redis.conf
	@echo "requirepass \"$(REDIS_PASSWORD)\"" >>  $(PWD)/conf/redis.conf
	@echo "masterauth \"$(REDIS_PASSWORD)\"" >>  $(PWD)/conf/redis.conf
####################################################################################
# Redis Cluster Creation
####################################################################################
.PHONY: redis-cluster redis-cluster-ssl
redis-cluster : redis-single
	@sh $(PWD)/scripts/redis-cluster.sh "$(REDIS_CLUSTER_SLAVES_NUMBER)" "$(NETWORK_NAME)"

redis-cluster-ssl : redis-generate-ssl redis-single-ssl
	@sh $(PWD)/scripts/redis-cluster.sh "$(REDIS_CLUSTER_SLAVES_NUMBER)" "$(NETWORK_NAME)" "TLS"
####################################################################################
# Redis Sentinel Creation
####################################################################################
.PHONY: sentinel-cluster sentinel-cluster-ssl
redis-sentinel : redis-cluster
	@sh $(PWD)/scripts/redis-sentinel.sh "$(REDIS_PASSWORD)" "$(REDIS_SENTINEL_PORT)" "$(NETWORK_NAME)"

redis-sentinel-ssl : redis-generate-ssl redis-cluster-ssl
	@sh $(PWD)/scripts/redis-sentinel.sh  "$(REDIS_PASSWORD)" "$(REDIS_SENTINEL_PORT)" "$(NETWORK_NAME)" "TLS"
####################################################################################
# Generate self-sign cert for TLS connection
####################################################################################
.PHONY: redis-generate-ssl
redis-generate-ssl:
	@wget --quiet $(REDIS_GEN_SSL_SH) -O $(PWD)/gencert.sh
	@sed -i '' 's/generate_cert redis "Generic-cert"/generate_cert redis "$(REDIS_SSL_CN)"/g' $(PWD)/gencert.sh
	@sed -i '' 's/tests\/tls/tls/g' $(PWD)/gencert.sh
	@chmod +x gencert.sh
	@sh gencert.sh
####################################################################################
# clean up
####################################################################################
.PHONY: redis-cleanup
redis-cleanup : 
	@sh $(PWD)/scripts/redis-cleanup.sh