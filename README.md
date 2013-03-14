# Redis benchmark against other databases
I've been tasked with doing a presentation on Redis, and I wanted to include some benchmarks against other NoSQL databases such as MongoDB, Cassandra, CouchDB and Riak.

The goal of this benchmarks was to make it as simple as possible in all aspects, with the following rationale:

* download database source;
* compile;
* run with defaults.

I tried to install everything with the minimum dependencies and simplicity, without spending too much time trying to fix any possible issue I had. The idea is to having a server running in the least amount of time possible.

**NOTE**: this is a far from perfect benchmark, I know.


## DB server

* EC2 Medium
  * 3.75 GiB memory
  * 2 EC2 Compute Unit (1 virtual core with 2 EC2 Compute Unit)
  * 410 GB instance storage
  * 32-bit or 64-bit platform
  * I/O Performance: Moderate
  * EBS-Optimized Available: No
  * API name: m1.medium
* Ubuntu Server 12.04.1 LTS

### Setup

```
sudo apt-get update
sudo apt-get -y install build-essential tmux
mkdir src
```

#### Redis

```
cd ~/src
wget http://redis.googlecode.com/files/redis-2.6.10.tar.gz
tar zxf redis-2.6.10.tar.gz
cd redis-2.6.10
make
```

Note: less than a minute. No dependencies.

#### MongoDB

```
cd ~/src
wget http://downloads.mongodb.org/src/mongodb-src-r2.2.3.tar.gz
tar zxf mongodb-src-r2.2.3.tar.gz
cd mongodb-src-r2.2.3
sudo apt-get -y install scons
```

Note: there's no indication in the README that I needed to install scons in order to compile MongoDB. More than 5 minutes compiling.

#### Cassandra

```
cd ~/src
wget http://apache.dattatec.com/cassandra/1.2.2/apache-cassandra-1.2.2-src.tar.gz
tar zxf apache-cassandra-1.2.2-src.tar.gz
sudo apt-get -Y install openjdk-6-jre ant
ant
```

Note: build failed. Binary core dumped.

#### CouchDB

```
cd ~/src
wget http://mirrors.dcarsat.com.ar/apache/couchdb/1.2.1/apache-couchdb-1.2.1.tar.gz
tar zxf apache-couchdb-1.2.1.tar.gz
cd  apache-couchdb-1.2.1
sudo apt-get -y install erlang libicu-dev libmozjs-dev libcurl4-openssl-dev
./configure
make
```

Note: binary core dumped.

## Client

* EC2 Micro
  * 613 MiB memory
  * Up to 2 EC2 Compute Units (for short periodic bursts)
  * EBS storage only
  * 32-bit or 64-bit platform
  * I/O Performance: Low
  * EBS-Optimized Available: No
  * API name: t1.micro
* Ubuntu Server 12.04.1 LTS

### Setup

```
sudo apt-get -y install ruby-1.9.3
sudo gem install redis cassandra couchdb mongodb riak
```

### Script
The benchmark ran it was very easy: iterate `1`, `10`, `100`, `1,000`, `10,000`, `100,000` and `1,000,000` over a simple model that has the following attributes:

* id: variable in the format `player:$i`;
* name: variable in the format `Player $i`;
* type: constant string `Developer`;
* age: constant number `34`;
* level: initially a constant `0`.

The benchmarks performs three operations in each instance of the model:

* storing;
* reading;
* updating `level` to the current iteration.

This script accepts the following two flags:

* `-h` indicate host to connect (default `127.0.0.1`) 
* `-n` indicate number of iterations (default `1,000`)

You can find the latest version of the script in the following repository: [https://github.com/citrusbyte/redis-benchmarks](https://github.com/citrusbyte/redis-benchmarks)

### Benchmark
I've ran the following command in my command line for benchmarking these database servers:

```
for i in 1 10 1000 10000 100000 1000000
do
  ./benchs.rb -h 10.0.0.1 -n $i | tee $i.log
done
```

You can find the results logs in the following repository: [https://github.com/citrusbyte/redis-benchmarks](https://github.com/citrusbyte/redis-benchmarks)

Remember that, as I couldn't get Cassandra nor CouchDB working easily, those weren't benchmarked.

#### `10` iterations
```
Redis
--------------------------------------------------------
                 user     system      total        real
write        0.000000   0.000000   0.000000 (  0.005587)
read         0.000000   0.000000   0.000000 (  0.005741)
update       0.010000   0.000000   0.010000 (  0.005117)
Total benchmark time for Redis: 0.01978361s

MongoDB
--------------------------------------------------------
                 user     system      total        real
write        0.000000   0.000000   0.000000 (  0.007547)
read         0.000000   0.000000   0.000000 (  0.007479)
update       0.000000   0.000000   0.000000 (  0.014906)
Total benchmark time for MongoDB: 0.034245423s

Riak
--------------------------------------------------------
                 user     system      total        real
write        0.010000   0.000000   0.010000 (  0.058750)
read         0.000000   0.000000   0.000000 (  0.033434)
update       0.020000   0.000000   0.020000 (  0.087879)
Total benchmark time for Riak: 0.190552601s

```

#### `100` iterations
```
Redis
--------------------------------------------------------
                 user     system      total        real
write        0.010000   0.000000   0.010000 (  0.055583)
read         0.020000   0.010000   0.030000 (  0.057843)
update       0.010000   0.000000   0.010000 (  0.049560)
Total benchmark time for Redis: 0.166689463s

MongoDB
--------------------------------------------------------
                 user     system      total        real
write        0.030000   0.010000   0.040000 (  0.087663)
read         0.020000   0.000000   0.020000 (  0.073081)
update       0.040000   0.000000   0.040000 (  0.164124)
Total benchmark time for MongoDB: 0.329832415s

Riak
--------------------------------------------------------
                 user     system      total        real
write        0.140000   0.010000   0.150000 (  0.597286)
read         0.120000   0.010000   0.130000 (  0.382307)
update       0.290000   0.020000   0.310000 (  1.024487)
Total benchmark time for Riak: 2.019069396s
```

#### `1000` iterations
```
Redis
--------------------------------------------------------
                 user     system      total        real
write        0.230000   0.010000   0.240000 (  0.822115)
read         0.210000   0.030000   0.240000 (  0.674979)
update       0.140000   0.010000   0.150000 (  0.498526)
Total benchmark time for Redis: 2.000050905s

MongoDB
--------------------------------------------------------
                 user     system      total        real
write        0.240000   0.020000   0.260000 (  0.741164)
read         0.210000   0.020000   0.230000 (  1.053450)
update       0.430000   0.050000   0.480000 (  2.194942)
Total benchmark time for MongoDB: 3.994837796s

Riak
--------------------------------------------------------
                 user     system      total        real
write        1.390000   0.170000   1.560000 (  6.635914)
read         1.350000   0.160000   1.510000 (  4.061969)
update       3.030000   0.280000   3.310000 ( 11.235330)
Total benchmark time for Riak: 21.959080865s
```

#### Other iterations
You can really appreciate that Redis performs faster, so there's no need to paste the other iterations numbers.

All I can say is that when I ran 1,000,000 iterations, MongoDB filled the hard disk.