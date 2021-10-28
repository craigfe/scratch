#!/usr/bin/env bash
set -euo pipefail

id=$(hexdump -n 4 -e '"%08x"' /dev/urandom)
log_dir="./logs/$id"
branches="auto-flush auto-flush-minus-unshallow auto-flush-minus-explicit-gc"

echo "$id" > latest_id
mkdir -p "$log_dir"
echo "Starting the bench matrix { id = $id; log_dir = $log_dir }"

for i in $(seq 1 5); do
  for a in $(seq 1 2); do
    for branch in $branches; do
      git checkout --quiet $branch

      head=$(git rev-parse --short HEAD)
      log_subdir="$log_dir/$branch"
      log_file="$log_subdir/a$a-i$i.log"
      data_file="$log_subdir/a$a-i$i.data"

      mkdir -p "$log_subdir"
      echo "Running { a = $a; i = $i; branch = $branch; log_file = $log_file }"
      echo "Parameters: { head = $head; a = $a; i = $i; branch = $branch }" > "$log_file"

      OCAMLRUNPARAM="a=$a" TIME_DATA="$data_file" ./run_benchmark.sh 2>&1 > "$log_file"
    done
  done
done



