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


