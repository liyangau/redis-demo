> Due to the Redis [license change](https://redis.io/blog/redis-adopts-dual-source-available-licensing/), even though it might not affect normal users, I feel it's better to explore alternatives. As a result, I've replaced Redis with [Valkey](https://valkey.io/) in this repository. However, for better compatibility, the make function, repo and containers name remains the same for now.

# Valkey Demo

> The knowledge I used on this repo is inspired by `That DevOps Guy`'s [YouTube](https://www.youtube.com/channel/UCFe9-V_rN9nLqVNiI8Yof3w) videos. Thanks him for sharing his knowledge.

This repo helps you to spin up valkey quickly. You can start a standalone valkey, valkey replication, valkey cluster or valkey sentinel quickly with docker.

Before you start, please understand this repo is designed to be used for testing purposes only. It does not have persistent storage hence all data in your test will be deleted once you stop/remove the container. Also in order to avoid file permission errors, a few commands requires root access. If you know how to fix file permission issue (I belive this is related to valkey container running as root), please feel free to submit a PR.

### Clone this repo

```bash
git clone https://github.com/liyangau/redis-demo
```

You will have everything you need inside `redis-demo/` folder.

### Create Network

These valkey containers need to be run on an external network. By default they are run in network `$NETWORK_NAME`.

If this network does not exist, this script will create this network for you.

### Change variables to suit your needs

There are a few variables you can change on `Makefile`

- **REDIS_VERSION**
  You can define the valkey version you want to use. (Default: `8.0`)

- **NETWORK_NAME**

  You can join valkey to your application network. Let's say your app is running in network `my-app`, you can use this parameter to run valkey within the same docker network. (Default: `redis-demo`)

- **REDIS_PASSWORD**

  This is the password to authenticate valkey. You need this password to authenicate with `valkey-cli`. (Default: `A-SUPER-STRONG-DEMO-PASSWORD` )

- **REDIS_SSL_CN**

  Common name of the SSL certificate. change it to anything suit your system, it is self-sign and won't be trusted  unless your system choose to. (Default: `valkey.test.demo`)

- **REDIS_REPLICATION_SLAVES_NUMBER**

  How many slaves in the valkey cluster you need. This support from 3 to 8 slaves. You can spin up more if you want but I limit my code to run at most 8 containers. (Default: `3`)

- **REDIS_CLUSTER_NODES_NUMBER**

  How many nodes on your valkey cluster. This support from 6 to 12 Nodes. My script create 1 replica per master node so setting this value to 6 will give you a cluster with 3 master node and 1 replica for each master. (Default: `6`)

- **REDIS_SENTINEL_PORT**

  You can set default sentinel port with this variable. (Default: `26379`)

### Commands

> When `-ssl` command is used, this script will generate the self-sign certificates and mount the certificates inside the containers and added the needful configuration to `valkey.conf` or `sentinel.conf` automatically.

#### Standalone Redis

- `make valkey-single`
- `make valkey-single-ssl`

You can use one of these two commands to start a single valkey container `redis-demo`. The configure file is downloaded from valkey [official website](https://github.com/valkey-io/valkey/blob/unstable/valkey.conf). In this setup, my script will change `bind 127.0.0.1` to `bind 0.0.0.0` and inject password define in `REDIS_PASSWORD` to the config file.

#### Redis Cluster

- `make valkey-cluster`
- `make valkey-cluster-ssl`

You can use one of these two commands to start a valkey cluster. You need to use 6 to 12 nodes for your cluster, nodes number is defined by `REDIS_CLUSTER_NODES_NUMBER` variable. By default this script create 6 nodes, 3 master and 3 slaves.

#### Redis Replication

- `make valkey-replication`
- `make valkey-replication-ssl`

You can use one of these two commands to start a valkey replication. The master container is `redis-demo` and the number of slaves is definied with **REDIS_REPLICATION_SLAVES_NUMBER** variable. By default this script create 3 slaves.

#### Redis Sentinel

- `make valkey-sentinel`
- `make valkey-sentinel-ssl`

These two command will spin up a valkey cluster first and then start 3 sentinel containers to monitor the cluster. If the master container  is down, sentinel will promot one of the slaves to be the master node.

#### Clean up

- `make valkey-cleanup`

This command will find all container has `valkey` in it, stop and remove these container. CAUTION: This command removes **ALL** contaners has `valkey` keyword in container name.