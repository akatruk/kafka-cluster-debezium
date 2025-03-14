# Настройка системы Change Data Capture (CDC) с Kafka, Debezium и PostgreSQL на Kubernetes

Этот документ предоставляет подробные инструкции по настройке и использованию системы отслеживания изменений данных (CDC) на базе Kafka и Debezium для PostgreSQL в среде Kubernetes.

## Архитектура решения

Система состоит из следующих компонентов:

1. **PostgreSQL** - источник данных, настроенный для логической репликации.
2. **Debezium Connect** - сервис для захвата изменений данных.
3. **Apache Kafka** - распределенная платформа обработки потоков для хранения и передачи сообщений.
4. **Strimzi Operator** - оператор Kubernetes для управления Kafka.
5. **Kafka UI** - веб-интерфейс для мониторинга и управления Kafka.

### Принцип работы CDC с Debezium

1. PostgreSQL записывает все изменения (INSERT, UPDATE, DELETE) в журнал транзакций (WAL).
2. Debezium постоянно считывает WAL через механизм логической репликации PostgreSQL.
3. Обнаруженные изменения преобразуются в события Kafka и публикуются в соответствующих топиках.
4. Приложения могут подписываться на эти топики для получения и обработки изменений данных.

## Требования

- Kubernetes кластер (рекомендуется Minikube для локальной разработки)
- Утилита командной строки `kubectl`
- Минимум 8GB оперативной памяти и 12 CPU для Minikube
- Docker или другой контейнерный движок

## Пошаговая инструкция по настройке

### 1. Подготовка окружения Kubernetes

Запуск Minikube с достаточными ресурсами:

```bash
minikube start --cpus=12 --memory=8192 --driver=docker
```

Создание необходимых пространств имен:

```bash
kubectl create namespace kafka-system
kubectl create namespace postgres
```

### 2. Развертывание Kafka с использованием Strimzi Operator

#### Установка Strimzi Operator

Strimzi Operator обеспечивает управление кластером Kafka в Kubernetes:

```bash
kubectl apply -f strimzi-operator.yaml -n kafka-system
```

Проверка, что оператор успешно запущен:

```bash
kubectl get pods -n kafka-system -l name=strimzi-cluster-operator
```

#### Развертывание кластера Kafka и ZooKeeper

```bash
kubectl apply -f kafka-cluster-resources.yaml -n kafka-system
```

Ожидание готовности кластера (может занять несколько минут):

```bash
kubectl wait --for=condition=ready pod -l strimzi.io/name=kafka-cluster-kafka -n kafka-system --timeout=600s
kubectl wait --for=condition=ready pod -l strimzi.io/name=kafka-cluster-zookeeper -n kafka-system --timeout=300s
```

#### Установка пользовательского интерфейса для Kafka

UI поможет визуализировать топики и сообщения:

```bash
kubectl apply -f kafka-ui.yaml -n kafka-system
```

Доступ к интерфейсу (после настройки port-forward):

```bash
kubectl port-forward svc/kafka-ui -n kafka-system 8080:8080
```

После этого UI будет доступен по адресу: http://localhost:8080

### 3. Настройка PostgreSQL с поддержкой логической репликации

#### Создание ConfigMap с конфигурацией PostgreSQL для Debezium

Файл `postgres-config.yaml` должен содержать следующие ключевые настройки:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: postgres
data:
  postgresql.conf: |
    # Настройки для расширений
    wal_level = logical              # Необходимо для логической репликации
    max_wal_senders = 4              # Максимальное количество процессов для отправки WAL
    max_replication_slots = 4        # Максимальное количество слотов репликации
    listen_addresses = '*'           # Прослушивание всех интерфейсов
  pg_hba.conf: |
    # TYPE  DATABASE        USER            ADDRESS                 METHOD
    local   all             all                                     trust
    host    all             all             0.0.0.0/0               md5
    host    all             all             ::/0                    md5 
```

Применение конфигурации:

```bash
kubectl apply -f postgres-config.yaml -n postgres
```

#### Развертывание PostgreSQL

Запуск PostgreSQL с настройками для Debezium:

```bash
kubectl apply -f postgres-deployment-debezium.yaml -n postgres
```

Проверка статуса и корректности настроек:

```bash
# Проверка статуса пода
kubectl get pods -n postgres -l app=postgres

# Проверка доступности PostgreSQL
kubectl exec -it $(kubectl get pods -n postgres -l app=postgres -o jsonpath='{.items[0].metadata.name}') -n postgres -- pg_isready

# Проверка настройки wal_level (должно быть "logical")
kubectl exec -it $(kubectl get pods -n postgres -l app=postgres -o jsonpath='{.items[0].metadata.name}') -n postgres -- psql -U postgres -c "SHOW wal_level;"
```

### 4. Установка и настройка Debezium Connect

#### Развертывание Debezium Connect

```bash
kubectl apply -f kafka-connector/debezium-connect.yaml -n kafka-system
```

Проверка запуска и готовности:

```bash
kubectl get pods -n kafka-system -l app=debezium-connect
```

#### Настройка и регистрация коннектора PostgreSQL

Создание файла конфигурации коннектора `postgres-connector.json`:

```json
{
  "name": "postgres-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "1",
    "database.hostname": "postgres.postgres.svc.cluster.local",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "postgres",
    "database.dbname": "postgresdb",
    "database.server.name": "postgres",
    "topic.prefix": "postgres",
    "table.include.list": "public.*",
    "plugin.name": "pgoutput",
    "transforms": "unwrap",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "false",
    "transforms.unwrap.delete.handling.mode": "rewrite",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "false",
    "value.converter.schemas.enable": "false"
  }
}
```

Описание ключевых параметров конфигурации:
- `connector.class`: Класс коннектора Debezium для PostgreSQL
- `database.hostname`: DNS-имя сервиса PostgreSQL в Kubernetes
- `database.server.name`: Логическое имя сервера (используется в именах топиков)
- `topic.prefix`: Префикс для топиков Kafka
- `table.include.list`: Список таблиц для отслеживания (здесь — все таблицы в схеме public)
- `plugin.name`: Плагин вывода для PostgreSQL (pgoutput — встроенный плагин логической репликации)
- `transforms`: Определяет преобразования событий для упрощения их структуры

Регистрация коннектора в Kafka Connect:

```bash
cat postgres-connector.json | kubectl exec -i $(kubectl get pods -n kafka-system -l app=debezium-connect -o jsonpath='{.items[0].metadata.name}') -n kafka-system -- curl -X POST -H "Content-Type: application/json" -d @- http://localhost:8083/connectors
```

Проверка статуса зарегистрированного коннектора:

```bash
kubectl exec -it $(kubectl get pods -n kafka-system -l app=debezium-connect -o jsonpath='{.items[0].metadata.name}') -n kafka-system -- curl -s http://localhost:8083/connectors/postgres-connector/status
```

## Тестирование и проверка работы системы

### 1. Создание тестовых данных в PostgreSQL

Создание тестовой таблицы:

```bash
kubectl exec -it $(kubectl get pods -n postgres -l app=postgres -o jsonpath='{.items[0].metadata.name}') -n postgres -- psql -U postgres -c "CREATE TABLE IF NOT EXISTS public.test_table (id SERIAL PRIMARY KEY, name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
```

Вставка тестовых данных:

```bash
kubectl exec -it $(kubectl get pods -n postgres -l app=postgres -o jsonpath='{.items[0].metadata.name}') -n postgres -- psql -U postgres -c "INSERT INTO public.test_table (name) VALUES ('test1'), ('test2'), ('test3');"
```

### 2. Проверка топиков Kafka

Список всех топиков (должен включать топики, созданные Debezium):

```bash
kubectl exec -it kafka-cluster-kafka-0 -n kafka-system -- bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

Созданные топики должны включать:
- `postgres.public.test_table` — топик с событиями изменений для таблицы test_table
- `postgres` — топик с метаданными

Просмотр информации о конкретном топике:

```bash
kubectl exec -it kafka-cluster-kafka-0 -n kafka-system -- bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic postgres.public.test_table
```

### 3. Чтение сообщений из топика с изменениями

```bash
kubectl exec -it kafka-cluster-kafka-0 -n kafka-system -- bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic postgres.public.test_table --from-beginning
```

Вы должны увидеть сообщения в формате JSON, содержащие вставленные данные.

### 4. Проверка захвата изменений в реальном времени

Откройте два терминала:

1. В первом терминале запустите потребителя Kafka для мониторинга сообщений:
```bash
kubectl exec -it kafka-cluster-kafka-0 -n kafka-system -- bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic postgres.public.test_table --from-beginning
```

2. Во втором терминале выполните операции вставки/обновления/удаления в PostgreSQL:
```bash
# Вставка новой записи
kubectl exec -it $(kubectl get pods -n postgres -l app=postgres -o jsonpath='{.items[0].metadata.name}') -n postgres -- psql -U postgres -c "INSERT INTO public.test_table (name) VALUES ('new_record');"

# Обновление записи
kubectl exec -it $(kubectl get pods -n postgres -l app=postgres -o jsonpath='{.items[0].metadata.name}') -n postgres -- psql -U postgres -c "UPDATE public.test_table SET name = 'updated_name' WHERE id = 1;"

# Удаление записи
kubectl exec -it $(kubectl get pods -n postgres -l app=postgres -o jsonpath='{.items[0].metadata.name}') -n postgres -- psql -U postgres -c "DELETE FROM public.test_table WHERE id = 2;"
```

В первом терминале вы должны увидеть соответствующие события для каждой операции.

## Устранение неполадок

### Проверка логов и диагностика

#### 1. Логи Debezium Connect

```bash
kubectl logs $(kubectl get pods -n kafka-system -l app=debezium-connect -o jsonpath='{.items[0].metadata.name}') -n kafka-system
```

Ищите ошибки, связанные с:
- Подключением к PostgreSQL
- Созданием топиков Kafka
- Обработкой изменений в WAL

#### 2. Проверка конфигурации PostgreSQL

```bash
# Проверка postgresql.conf
kubectl exec -it $(kubectl get pods -n postgres -l app=postgres -o jsonpath='{.items[0].metadata.name}') -n postgres -- cat /etc/postgresql/postgresql.conf

# Проверка pg_hba.conf
kubectl exec -it $(kubectl get pods -n postgres -l app=postgres -o jsonpath='{.items[0].metadata.name}') -n postgres -- cat /etc/postgresql/pg_hba.conf
```

#### 3. Проверка доступности и сетевого подключения

```bash
# Проверка работы DNS
kubectl exec -it $(kubectl get pods -n kafka-system -l app=debezium-connect -o jsonpath='{.items[0].metadata.name}') -n kafka-system -- nslookup postgres.postgres.svc.cluster.local

# Проверка статуса коннектора
kubectl exec -it $(kubectl get pods -n kafka-system -l app=debezium-connect -o jsonpath='{.items[0].metadata.name}') -n kafka-system -- curl -s http://localhost:8083/connectors/postgres-connector/status
```

### Перезапуск компонентов при проблемах

#### 1. Перезапуск коннектора

```bash
# Удаление коннектора
kubectl exec -it $(kubectl get pods -n kafka-system -l app=debezium-connect -o jsonpath='{.items[0].metadata.name}') -n kafka-system -- curl -X DELETE http://localhost:8083/connectors/postgres-connector

# Повторная регистрация коннектора
cat postgres-connector.json | kubectl exec -i $(kubectl get pods -n kafka-system -l app=debezium-connect -o jsonpath='{.items[0].metadata.name}') -n kafka-system -- curl -X POST -H "Content-Type: application/json" -d @- http://localhost:8083/connectors
```

#### 2. Перезапуск пода Debezium Connect

```bash
kubectl delete pod $(kubectl get pods -n kafka-system -l app=debezium-connect -o jsonpath='{.items[0].metadata.name}') -n kafka-system
```

#### 3. Перезапуск PostgreSQL при необходимости

```bash
kubectl delete pod $(kubectl get pods -n postgres -l app=postgres -o jsonpath='{.items[0].metadata.name}') -n postgres
```

## Часто встречающиеся проблемы и их решения

### 1. Ошибка подключения Debezium к PostgreSQL

**Проблема**: В логах Debezium видны ошибки подключения к PostgreSQL.

**Решение**:
- Убедитесь, что сервис PostgreSQL доступен по DNS-имени `postgres.postgres.svc.cluster.local`
- Проверьте, что настройки `pg_hba.conf` позволяют подключения с хостов Kubernetes
- Проверьте правильность учетных данных в конфигурации коннектора

### 2. Топики не создаются автоматически

**Проблема**: После регистрации коннектора топики не появляются в Kafka.

**Решение**:
- Проверьте логи Debezium Connect на наличие ошибок
- Убедитесь, что коннектор имеет статус `RUNNING`
- Возможно, у Kafka Connect нет прав на создание топиков - проверьте настройки RBAC

### 3. Изменения не отслеживаются 

**Проблема**: Несмотря на корректную настройку, изменения в базе данных не появляются в топиках Kafka.

**Решение**:
- Убедитесь, что таблицы попадают под фильтр `table.include.list` в конфигурации коннектора
- Проверьте, что в PostgreSQL для таблицы включены первичные ключи
- Проверьте настройку `wal_level = logical` и перезагрузите PostgreSQL, если она была изменена

## Заключение

Настроенная система CDC обеспечивает захват и отслеживание изменений в реальном времени из PostgreSQL в Kafka. Это решение может использоваться для:

- Синхронизации данных между различными системами
- Построения микросервисных архитектур с асинхронной коммуникацией
- Создания реплик данных для аналитики
- Аудита изменений данных

Для производственного использования рекомендуется дополнительно настроить:
- Безопасность (TLS/SSL, аутентификация)
- Мониторинг и оповещения
- Резервное копирование и стратегии восстановления
- Управление ресурсами (настройка limits и requests)

