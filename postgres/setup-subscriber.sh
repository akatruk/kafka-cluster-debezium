#!/bin/bash

# Apply the configuration and create replica
kubectl apply -f postgres/postgres-replica-config.yaml
kubectl apply -f postgres/postgres-replica.yaml

# Wait for the replica database to be ready
echo "Waiting for replica database to be ready..."
kubectl rollout status statefulset/postgres-replica -n postgres

# Create schema and tables in the replica (needs to match the publisher)
echo "Creating schema and tables in the replica..."
# Export schema from publisher
kubectl exec -it -n postgres postgres-0 -- pg_dump -U postgres -d postgresdb --schema-only > schema.sql

# Apply schema to replica (excluding any publication/subscription objects)
cat schema.sql | kubectl exec -i -n postgres postgres-replica-0 -- psql -U postgres -d postgresdb

# Create subscription
echo "Creating subscription..."
kubectl exec -it -n postgres postgres-replica-0 -- psql -U postgres -d postgresdb -c "CREATE SUBSCRIPTION all_tables_subscription CONNECTION 'host=postgres.postgres.svc.cluster.local port=5432 dbname=postgresdb user=postgres password=postgres' PUBLICATION all_tables;"

# Verify the subscription was created
echo "Verifying subscription..."
kubectl exec -it -n postgres postgres-replica-0 -- psql -U postgres -d postgresdb -c "\dRs+"

echo "Subscriber setup complete!" 