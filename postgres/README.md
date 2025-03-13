# PostgreSQL Setup

This folder contains Kubernetes manifests and setup scripts for PostgreSQL database with logical replication.

For detailed documentation, please see the main [POSTGRES.md](../POSTGRES.md) file in the root directory.

## Files

- `postgres.yaml`: Primary PostgreSQL deployment
- `postgres-publisher-config.yaml`: Config for primary database
- `postgres-replica.yaml`: Replica PostgreSQL deployment
- `postgres-replica-config.yaml`: Config for replica database
- `setup-publisher.sh`: Script to set up the publisher
- `setup-subscriber.sh`: Script to set up the subscriber
- `postgres-connector.yaml`: Debezium connector for Kafka
- `create-connector-job.yaml`: Job to create the connector

## Quick Start

```bash
# Set up the primary database with publication
./setup-publisher.sh

# Set up the replica database with subscription
./setup-subscriber.sh
``` 