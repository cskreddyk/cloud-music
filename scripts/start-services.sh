#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

mkdir -p logs

pids=()

cleanup() {
    echo "Stopping CloudMusic services..."

    for pid in "${pids[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
}

trap cleanup EXIT
trap 'exit 0' INT TERM

for service in services/*; do

    name=$(basename "$service")

    echo "Starting $name..."

    HOST=127.0.0.1 node "$service/src/index.js" \
        > "logs/$name.log" 2>&1 &

    pids+=("$!")

done

echo "=================================="
echo "12 microservice processes launched"
echo "Logs directory: logs/"
echo "Press Ctrl+C to stop services"
echo "=================================="

wait -n
