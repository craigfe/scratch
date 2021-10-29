#!/usr/bin/env bash
set -euo pipefail

id=$(hexdump -n 4 -e '"%08x"' /dev/urandom)
log_dir="./logs/$id"

# Variables of our matrix:
allocation_strategies="0 2"
branches="auto-flush auto-flush-minus-unshallow auto-flush-minus-explicit-gc"
iterations=5

echo "$id" > latest_id
mkdir -p "$log_dir"
echo "Starting the bench matrix { id = $id; log_dir = $log_dir }"

for i in $(seq 1 $iterations); do
  for a in $allocation_strategies; do
    for branch in $branches; do
      git checkout --quiet $branch

      head=$(git rev-parse --short HEAD)
      log_subdir="$log_dir/$branch"
      log_file="$log_subdir/a$a-i$i.log"
      data_file_prefix="$log_subdir/a$a-i$i"

      mkdir -p "$log_subdir"
      echo "Running { a = $a; i = $i; branch = $branch; log_file = $log_file }"
      echo "Parameters: { head = $head; a = $a; i = $i; branch = $branch }" > "$log_file"

      OCAMLRUNPARAM="a=$a" TIME_DATA="$data_file_prefix" ./run_benchmark.sh 2>&1 > "$log_file"
    done
  done
done



