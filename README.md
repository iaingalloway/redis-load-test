# Redis Load Testing

A basic redis load test to measure the difference between RDB, AOF with fsync every 1 second, and AOF with fsync always. The load test is performed using [memtier_benchmark](https://github.com/RedisLabs/memtier_benchmark).

## Prerequisites

- Docker and Docker Compose (e.g. Docker Desktop)

## Setup

Run the load test using the following script:

```bash
./run-tests.sh
```

You can customize the memtier_benchmark parameters by passing arguments to the script:

```bash
./run-tests.sh -t 8 -c 100 -n 200000 -v /mnt/f/redis-load-testing/data
```

This will run the tests with 8 threads, 100 connections, and 200,000 requests per thread.

Results from a local run can be found in the logs directory.

## Results

On my machine, I get the following results:

| Configuration | Average throughput |
|---------------|--------------------|
| RDB           | 11.4 MB/s          |
| AOF default   |  9.56 MB/s         |
| AOF always    |  0.152 MB/s        |

