# Настройка Kafka и Debezium Connect на Kubernetes

Этот документ предоставляет подробные инструкции по настройке и использованию окружения Kafka и Debezium Connect на Kubernetes.

## Требования

- Kubernetes кластер (рекомендуется Minikube для локальной разработки)
- Утилита командной строки `kubectl`
- Минимум 8GB оперативной памяти и 12 CPU для Minikube

## Инструкции по настройке

### 1. Запуск Minikube с необходимыми ресурсами

```bash
minikube start --cpus=12 --memory=8192 --driver=docker
```

### 2. Создание Namespaces

```bash
kubectl apply -f strimzi-operator.yaml -n kafka-system
```

### 3. Развертывание оператора Strimzi для Kafka

```bash
kubectl apply -f strimzi-operator.yaml -n kafka-system
```

### 4. Развертывание кластера Kafka

```bash
kubectl apply -f kafka-cluster-resources.yaml -n kafka-system
```

Подождите, пока кластер Kafka будет готов (это может занять несколько минут):

```bash
kubectl wait --for=condition=ready pod -l strimzi.io/name=kafka-cluster-kafka -n kafka-system --timeout=600s
kubectl wait --for=condition=ready pod -l strimzi.io/name=kafka-cluster-zookeeper -n kafka-system --timeout=300s
```

### 5. Развертывание UI для Kafka

```bash
kubectl apply -f kafka-ui.yaml -n kafka-system
```

### 6. Развертывание PostgreSQL

```
kubectl apply -f postgres.yaml -n postgres
```

### 7. Развертывание Debezium Connect

```bash
kubectl apply -f debezium-connect-direct.yaml -n kafka-system
```

```bash
curl -X POST -H "Content-Type: application/json" --data @postgres-connector.json http://localhost:8083/connectors
```

## Проверка настроек

Проверка топиков Kafka

```bash
# Список всех топиков
kubectl exec -it kafka-cluster-kafka-0 -n kafka-system -- bin/kafka-topics.sh --bootstrap-server kafka-cluster-kafka-bootstrap:9092 --list

# Описание конкретного топика
kubectl exec -it kafka-cluster-kafka-0 -n kafka-system -- bin/kafka-topics.sh --bootstrap-server kafka-cluster-kafka-bootstrap:9092 --describe --topic [TOPIC_NAME]
```

### Потребление сообщений из топиков

```bash
kubectl exec -it kafka-cluster-kafka-0 -n kafka-system -- bin/kafka-console-consumer.sh --bootstrap-server kafka-cluster-kafka-bootstrap:9092 --topic [TOPIC_NAME] --from-beginning
```

