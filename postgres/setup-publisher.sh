#!/bin/bash

# Apply the publisher configuration
kubectl apply -f postgres/postgres-publisher-config.yaml

# Restart the primary PostgreSQL to apply the configuration
kubectl rollout restart statefulset/postgres -n postgres

# Wait for the primary database to be ready
echo "Waiting for primary database to be ready..."
kubectl rollout status statefulset/postgres -n postgres

# Create a publication for all tables
echo "Creating publication for all tables..."
kubectl exec -it -n postgres postgres-0 -- psql -U postgres -d postgresdb -c "CREATE PUBLICATION all_tables FOR ALL TABLES;"

# Verify the publication was created
echo "Verifying publication..."
kubectl exec -it -n postgres postgres-0 -- psql -U postgres -d postgresdb -c "\dRp+"

echo "Publisher setup complete!" 