#!/usr/bin/env bash
# Needs `moreutils` (for `ts`)

STORE_PRISTINE="/bench/craig/data/pristine/.tezos-node/"
STORE_DIRTY="/bench/craig/data/.tezos-node/"
TEZOS_NODE="src/bin_node/main.exe"
TEZOS_CLIENT="src/bin_client/main_client.exe"
WALLET="./yes-wallet"

if [[ ! -d "$WALLET" ]]; then
	echo "- Creating a noop Tezos wallet"
	dune exec scripts/yes-wallet/yes_wallet.exe create minimal in "$WALLET"
fi

if [[ ! -d "$STORE_PRISTINE" ]]; then
	echo "- Extracting a new pristine store from the archive"
	tar -I lz4 -xvf /bench/ngoguey/ro/migration_node_1month.tar.lz4 -C "$(basename $STORE_PRISTINE)"
fi

if [[ "$#" = 0 || "$1" != "--no-prepare" ]]; then
	echo "- Copying the pristine store to a fresh temporary location"
	rm -rf "$STORE_DIRTY"
	cp -r "$STORE_PRISTINE" "$STORE_DIRTY"

	echo "- Building the 'tezos-node' and 'tezos-client' binaries"
	dune build "./$TEZOS_NODE" "./$TEZOS_CLIENT"
else
	echo "- Skipping the preparation step as requested"
fi

random_unused_port () {
	comm -23 <(seq 49152 65535) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -n 1 || true
}

RPC_PORT=$(random_unused_port)
NET_PORT=$(random_unused_port)

echo "- Starting the 'tezos-node' process { rpc_port = $RPC_PORT; net_port = $NET_PORT }"

if [ -n "$TIME_DATA" ]; then time_output="--output=$TIME_DATA.node.data"; else time_output=""; fi
/usr/bin/time $time_output -v "_build/default/$TEZOS_NODE" run \
	--data-dir "$STORE_DIRTY" \
	--private-mode \
	--no-bootstrap-peers \
	--net-addr localhost:$NET_PORT \
	--rpc-addr localhost:$RPC_PORT \
	--connections 0 \
	--synchronisation-threshold 0 2>&1 | \
	ts "  [node]" &
node_pid=$!

sleep 5 # Give the node some time to start
rm -f ./yes-wallet/blocks

if [ -n "$TIME_DATA" ]; then time_output="--output=$TIME_DATA.client.data"; else time_output=""; fi
/usr/bin/time $time_output -v "_build/default/$TEZOS_CLIENT" \
	--base-dir ./yes-wallet \
	--endpoint http://localhost:$RPC_PORT \
	bake for foundation1 2>&1 | \
	ts "[client]"

kill -TERM $node_pid


