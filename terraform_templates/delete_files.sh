#! /bin/bash
rm -rf group_vars/all.yml
rm -rf roles/kafka/templates/kafka1-properties.j2
rm -rf roles/kafka/templates/kafka2-properties.j2
rm -rf roles/kafka/templates/kafka3-properties.j2
rm -rf roles/zookeeper/templates/z.j2
# rm -rf terraform.tfstate terraform.tfstate.backup