#  _____          _ _       _____                       
# |  __ \        | (_)     |  __ \                      
# | |__) |___  __| |_ ___  | |  | | ___ _ __ ___   ___  
# |  _  // _ \/ _` | / __| | |  | |/ _ \ '_ ` _ \ / _ \ 
# | | \ \  __/ (_| | \__ \ | |__| |  __/ | | | | | (_) |
# |_|  \_\___|\__,_|_|___/ |_____/ \___|_| |_| |_|\___/  

REDIS_6_OFFICIAL_CONF=https://raw.githubusercontent.com/redis/redis/6.0/redis.conf
REDIS_PASSWORD=3C597CEA-C3DD-4067-8BD4-4618606CD9FF
KONG_NETWORK_NAME=kong-ee-net
REDIS_SSL_CN=redis.test.demo
REDIS_CLUSTER_SLAVES_NUMBER=3

####################################################################################
# Cluster Creation
# This will map the host 8001 to NodePort 32001 and 
# host 8002 to NodePort 32002
####################################################################################
.PHONY: redis-single redis/redis.conf redis-cluster
redis-single: redis/redis.conf
	@sh $(PWD)/scripts/redis-single.sh "$(KONG_NETWORK_NAME)"

redis/redis.conf:
	@mkdir -p $(PWD)/conf
	@wget --quiet $(REDIS_6_OFFICIAL_CONF) -O $(PWD)/conf/redis.conf
	@sed -i '' 's/bind 127.0.0.1/bind 0.0.0.0/g' $(PWD)/conf/redis.conf
	@echo "requirepass $(REDIS_PASSWORD)" >>  $(PWD)/conf/redis.conf
	@echo "masterauth $(REDIS_PASSWORD)" >>  $(PWD)/conf/redis.conf

####################################################################################
# Cluster Creation
####################################################################################
redis-cluster : redis-single
	@sh $(PWD)/scripts/redis-cluster.sh "$(REDIS_CLUSTER_SLAVES_NUMBER)" "$(KONG_NETWORK_NAME)"

####################################################################################
# TLS Enable
####################################################################################
.PHONY: redis-generate-ssl
redis-generate-ssl:
	@wget --quiet 'https://links.aufomm.com/gencert' -O $(PWD)/gencert.sh
	@sed -i '' 's/generate_cert redis "SSL"/generate_cert redis "$(REDIS_SSL_CN)"/g' $(PWD)/gencert.sh
	@chmod +x gencert.sh
	@sh gencert.sh
####################################################################################
# clean up
####################################################################################
redis-cleanup : 
	@sh $(PWD)/scripts/redis-cleanup.sh