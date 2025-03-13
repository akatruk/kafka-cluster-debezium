#!/bin/bash

# Get the name of the Debezium Connect pod
DEBEZIUM_POD=$(kubectl get pods -n kafka-system -l app=debezium-connect -o jsonpath='{.items[0].metadata.name}')

if [ -z "$DEBEZIUM_POD" ]; then
  echo "Debezium Connect pod not found"
  exit 1
fi

echo "Found Debezium Connect pod: $DEBEZIUM_POD"

# Function to run a command in the Debezium Connect pod
run_in_pod() {
  local command="$1"
  echo "Running: $command"
  kubectl exec -it -n kafka-system "$DEBEZIUM_POD" -- bash -c "$command"
  echo ""
}

# Check if Debezium Connect API is running
echo "Checking if Debezium Connect API is running..."
run_in_pod "curl -s http://localhost:8083/"

# List all connectors
echo "Listing all connectors..."
run_in_pod "curl -s http://localhost:8083/connectors"

# Get connector config
echo "Getting connector config for postgres-sensor-connector..."
run_in_pod "curl -s -X GET http://localhost:8083/connectors/postgres-sensor-connector/config"

# Get connector status
echo "Getting connector status for postgres-sensor-connector..."
run_in_pod "curl -s http://localhost:8083/connectors/postgres-sensor-connector/status"

# Stop the connector
echo "Stopping postgres-sensor-connector..."
run_in_pod "curl -s -X PUT http://localhost:8083/connectors/postgres-sensor-connector/stop"

# Get connector offsets
echo "Getting offsets for postgres-sensor-connector..."
run_in_pod "curl -s http://localhost:8083/connectors/postgres-sensor-connector/offsets"

echo "All commands completed." 