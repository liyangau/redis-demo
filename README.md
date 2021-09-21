# Redis Demo

> The knowledge I used on this repo is inspired by `That DevOps Guy`'s [YouTube](https://www.youtube.com/channel/UCFe9-V_rN9nLqVNiI8Yof3w) videos. Thanks him for sharing his knowledge.

This repo helps you to spin up redis quickly. You can start a standalone redis, redis replication, redis cluster or redis sentinel quickly with docker.

Before you start, please understand this repo is designed to be used for testing purposes only. It does not have persistent storage hence all data in your test will be deleted once you stop/remove the container. Also in order to avoid file permission errors, a few commands requires root access. If you know how to fix file permission issue between docker container and host, please submit a PR to help the project.

### Clone this repo

```bash
git clone https://github.com/liyangau/redis-demo
```

You will have everything you need inside `redis-demo/` folder.

### Create Network

```bash
docker network create redis-demo
```

These redis containers need to be run on an external network. By default they are run in network `redis-demo`.
You can define the network vis **NETWORK_NAME** variable below. 

### Change variables to suit your needs

There are a few variables you can change on `Makefile`

- **NETWORK_NAME**

  You can join redis to your application network. Let's say your app is running in network `my-app`, you can use this parameter to run redis within the same docker network. (Default: `redis-demo`)

- **REDIS_PASSWORD**

  This is the password to authenticate redis. You need this password to authenicate with `redis-cli`. (Default: `A-SUPER-STRONG-DEMO-PASSWORD` )

- **REDIS_SSL_CN**

  Common name of the SSL certificate. change it to anything suit your system, it is self-sign and won't be trusted  unless your system choose to. (Default: `redis.test.demo`)

- **REDIS_REPLICATION_SLAVES_NUMBER**

  How many slaves in the redis cluster you need. This support from 3 to 8 slaves. You can spin up more if you want but I limit my code to run at most 8 containers. (Default: `3`)

- **REDIS_CLUSTER_NODES_NUMBER**

  How many nodes on your redis cluster. This support from 6 to 12 Nodes. My script create 1 replica per master node so setting this value to 6 will give you a cluster with 3 master node and 1 replica for each master. (Default: `6`)

- **REDIS_SENTINEL_PORT**

  You can set default sentinel port with this variable. (Default: `26379`)

### Commands

> When `-ssl` command is used, this script will generate the self-sign certificates and mount the certificates inside the containers and added the needful configuration to `redis.conf` or `sentinel.conf` automatically. 

#### Standalone Redis

- `make redis-single` 
- `make redis-single-ssl`

You can use one of these two commands to start a single redis container `redis-demo`. The configure file is downloaded from redis [official website](https://raw.githubusercontent.com/redis/redis/6.0/redis.conf). In this setup, my script will change `bind 127.0.0.1` to `bind 0.0.0.0` and inject password define in `REDIS_PASSWORD` to the config file.

#### Redis Cluster

- `make redis-cluster`
- `make redis-cluster-ssl`

You can use one of these two commands to start a redis cluster. You need to use 6 to 12 nodes for your cluster, nodes number is defined by `REDIS_CLUSTER_NODES_NUMBER` variable. By default this script create 6 nodes, 3 master and 3 slaves.

#### Redis Replication

- `make redis-replication`
- `make redis-replication-ssl`

You can use one of these two commands to start a redis replication. The master container is `redis-demo` and the number of slaves is definied with **REDIS_REPLICATION_SLAVES_NUMBER** variable. By default this script create 3 slaves. 

#### Redis Sentinel

- `make redis-sentinel`
- `make redis-sentinel-ssl`

These two command will spin up a redis cluster first and then start 3 sentinel containers to monitor the cluster. If the master container  is down, sentinel will promot one of the slaves to be the master node.

#### Clean up

- `make redis-cleanup`

This command will find all container has `redis` in it, stop and remove these container. CAUTION: This command removes **ALL** contaners hence data inside the container will be deleted forever.