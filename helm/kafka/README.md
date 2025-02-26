# Kafka Cluster with Debezium Connect Helm Chart

This Helm chart deploys a production-ready Kafka cluster using Strimzi operator along with Debezium connectors for Change Data Capture (CDC).

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure

## Components

- Strimzi Kafka Operator
- Apache Kafka Cluster
- Kafka Connect with Debezium connectors:
  - MongoDB
  - MySQL
  - PostgreSQL
  - SQL Server

## Installation

1. Add the Strimzi Helm repository:
```bash
helm repo add strimzi https://strimzi.io/charts/
helm repo update
```

2. Install the chart:
```bash
# Create a dedicated namespace
kubectl create namespace kafka-system

# Install the chart
helm install kafka-cluster ./helm/debezium-connect \
  --namespace kafka-system \
  --set kafka.enabled=true \
  --set strimzi.enabled=true
```

## Configuration

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `strimzi.enabled` | Enable Strimzi Operator installation | `true` |
| `kafka.enabled` | Enable Kafka Cluster installation | `true` |
| `kafka.replicas` | Number of Kafka brokers | `3` |
| `kafka.storage.size` | Storage size for Kafka brokers | `100Gi` |
| `connect.replicas` | Number of Kafka Connect replicas | `1` |
| `connect.plugins` | Enabled Debezium connectors | MongoDB, MySQL, PostgreSQL, SQL Server |

### Storage Configuration

The chart uses persistent volume claims for Kafka brokers. You can configure storage in `values.yaml`:

```yaml
kafka:
  storage:
    type: persistent-claim
    size: 100Gi
    deleteClaim: false
```

## Usage

### Accessing Kafka

The Kafka cluster will be accessible within the Kubernetes cluster at:
```
kafka-cluster-kafka-bootstrap.kafka-system:9092
```

### Deploying Connectors

To deploy a Debezium connector, create a `KafkaConnector` custom resource. Example for MySQL:

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaConnector
metadata:
  name: mysql-connector
  namespace: kafka-system
  labels:
    strimzi.io/cluster: debezium-connect-cluster
spec:
  class: io.debezium.connector.mysql.MySqlConnector
  tasksMax: 1
  config:
    database.hostname: mysql
    database.port: 3306
    database.user: debezium
    database.password: dbz
    database.server.id: 184054
    database.server.name: dbserver1
    database.include.list: inventory
    database.history.kafka.bootstrap.servers: kafka-cluster-kafka-bootstrap:9092
    database.history.kafka.topic: schema-changes.inventory
```

## Monitoring

The chart includes default configuration for metrics using:
- JMX Exporter for Kafka metrics
- Prometheus annotations for scraping metrics

## Uninstallation

To uninstall the chart:
```bash
helm uninstall kafka-cluster -n kafka-system
```

## Support

For issues and support, please refer to:
- [Strimzi Documentation](https://strimzi.io/documentation/)
- [Debezium Documentation](https://debezium.io/documentation/) 