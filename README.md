# Apache Kafka

Terraform & Ansible deploy Apache Kafka cluster on AWS

/etc/systemd/system/zookeeper.service
/etc/apache-zookeeper-3.7.0/bin/zkServer.sh --config /etc/apache-zookeeper-3.7.0/conf/zoo.cfg start
ExecStart=/kafka/kafka_2.12-2.8.1/bin/zookeeper-server-start.sh /kafka/kafka_2.12-2.8.1/config/zookeeper.properties
ExecStop=/kafka/kafka_2.12-2.8.1/bin/zookeeper-server-stop.sh /kafka/kafka_2.12-2.8.1/config/zookeeper.properties
systemctl status zookeeper.service
sudo systemctl stop zookeeper.service
sudo systemctl daemon-reload
sudo systemctl start zookeeper.service

/kafka/kafka_2.12-2.8.1/config/zookeeper.properties