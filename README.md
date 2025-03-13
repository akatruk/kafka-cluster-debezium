# Kafka и Debezium Connect на Kubernetes #

Компоненты

Apache Kafka: Платформа потоковой обработки событий для высокопроизводительной, отказоустойчивой, публикационно-подписочной передачи сообщений.

ZooKeeper: Сервис координации для распределённых приложений (используется Kafka).

Debezium Connect: Платформа потоковой передачи данных для отслеживания изменений в базе данных (CDC).

PostgreSQL: Реляционная база данных с поддержкой CDC через Debezium.

Kafka UI: Веб-интерфейс для управления кластером Kafka.

## Архитектура ##

Настройка использует оператор Strimzi Kafka для управления кластером Kafka. База данных PostgreSQL настроена для отслеживания изменений, а Debezium Connect передает изменения в Kafka.


PostgreSQL Database → Debezium Connect → Kafka Cluster → Consumers
                                           ↑
                                        Kafka UI

## Файлы и их назначение ##

kafka-cluster-resources.yaml: Основная конфигурация кластера Kafka с правильным распределением ресурсов для брокеров Kafka и узлов ZooKeeper.

debezium-connect-direct.yaml: Развертывание Debezium Connect в Kubernetes с конфигурацией контейнера, переменными окружения и определением сервиса.

postgres-connector.json: JSON-конфигурация для коннектора Debezium PostgreSQL, определяющая параметры подключения к базе данных и поведение CDC.

postgres.yaml: Конфигурация развертывания базы данных PostgreSQL, включая необходимые настройки для CDC с Debezium.

kafka-ui.yaml: Конфигурация развертывания веб-интерфейса Kafka UI.

strimzi-operator.yaml: Развертывание оператора Strimzi Kafka в Kubernetes для управления ресурсами Kafka.

## PostgreSQL Database

The PostgreSQL database setup, including logical replication between primary and replica instances, is documented in [POSTGRES.md](POSTGRES.md).

## Troubleshooting and Fixes ##

### Fixing Kafka Cluster CrashLoopBackOff Issues

If your Kafka broker pod (`kafka-cluster-kafka-0`) or ZooKeeper pod (`kafka-cluster-zookeeper-0`) enters a CrashLoopBackOff state, it's often due to connectivity issues between Kafka and ZooKeeper. Here's how to resolve this:

1. **Identify the issue**: Check the logs of the Kafka broker pod to confirm it's a ZooKeeper connectivity issue:
   ```bash
   kubectl logs kafka-cluster-kafka-0 -n kafka-system
   ```
   Look for `ZooKeeperClientTimeoutException` errors indicating connection timeouts.

2. **Restart the ZooKeeper pod**:
   ```bash
   kubectl delete pod kafka-cluster-zookeeper-0 -n kafka-system
   ```
   This forces Kubernetes to create a fresh ZooKeeper pod.

3. **Delete and recreate the Kafka custom resource**:
   ```bash
   kubectl delete kafka kafka-cluster -n kafka-system
   kubectl apply -f kafka-cluster-resources.yaml
   ```
   This approach ensures that all Kafka components are recreated with fresh configuration.

4. **Wait for the components to initialize**:
   The pods should start in the following order:
   - ZooKeeper pod
   - Kafka broker pod
   - Entity Operator pod
   - Debezium Connect pod

This procedure resolves most common issues with Strimzi Kafka deployments, particularly those related to SSL connectivity problems between Kafka and ZooKeeper.


