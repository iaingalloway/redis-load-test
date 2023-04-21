#!/bin/bash

wait_for_redis() {
  host=$1
  port=$2
  timeout=$3

  start_time=$(date +%s)
  while true; do
    (echo -e "PING\r\n"; sleep 1) | nc -w 1 $host $port | grep -q PONG && break

    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [ $elapsed_time -ge $timeout ]; then
      echo "Timed out waiting for redis at $host:$port"
      exit 1
    fi

    sleep 1
  done
}

# Default values for memtier_benchmark arguments
THREADS=4
CONNECTIONS=50
REQUESTS=10000

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -t|--threads)
      THREADS="$2"
      shift
      shift
      ;;
    -c|--connections)
      CONNECTIONS="$2"
      shift
      shift
      ;;
    -n|--requests)
      REQUESTS="$2"
      shift
      shift
      ;;
    *)
      echo "Unknown option: $key"
      exit 1
      ;;
  esac
done

echo "Starting redis containers..."
docker-compose up -d --build

echo "Waiting for redis instances to be ready..."
wait_for_redis 127.0.0.1 6379 60
wait_for_redis 127.0.0.1 6380 60
wait_for_redis 127.0.0.1 6381 60

mkdir -p logs

echo "Running memtier_benchmark for RDB..."
docker run --network=host -v $(pwd)/logs:/logs redislabs/memtier_benchmark:latest -s 127.0.0.1 -p 6379 -t $THREADS -c $CONNECTIONS -n $REQUESTS -o /logs/rdb.log

echo "Running memtier_benchmark for AOF with default settings..."
docker run --network=host -v $(pwd)/logs:/logs redislabs/memtier_benchmark:latest -s 127.0.0.1 -p 6380 -t $THREADS -c $CONNECTIONS -n $REQUESTS -o /logs/aof_1s.log

echo "Running memtier_benchmark for AOF flushing always..."
docker run --network=host -v $(pwd)/logs:/logs redislabs/memtier_benchmark:latest -s 127.0.0.1 -p 6381 -t $THREADS -c $CONNECTIONS -n $REQUESTS -o /logs/aof_always.log

echo "Stopping Redis containers..."
docker-compose down
