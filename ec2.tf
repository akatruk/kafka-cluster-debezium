provider "aws" {
    access_key = var.access_key
    secret_key = var.secret_key
    region     = var.region
}

data "template_file" "myuserdata" {
  template = "${file("${path.cwd}/bootstrap.sh")}"
}

resource "aws_instance" "amazon" {
    count = var.instance_count
    ami = var.ami_id
    instance_type = "t2.small"
    subnet_id = "subnet-064911dfd026b5dc0"
    tags = {
        Name = "kafka-${count.index + 1}"
        project = "kafka"
    }
    key_name = aws_key_pair.my_key.id
}

resource "aws_key_pair" "my_key" {
  key_name   = "deployer-key1"
  public_key = "${file("/Users/akatruk/.ssh/id_rsa.pub")}"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ec2"
  description = "Allow ssh inbound traffic"

  dynamic "ingress" {
    for_each = ["22", "88"]
    content {
    description = "ssh from VPC"
    from_port   = ingress.value
    to_port     = ingress.value
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
    Owner = "Andrey Katruk"
  }
}

data "aws_route53_zone" "main" {
  name         = "katruk.ru"
}

resource "aws_route53_record" "kafka" {
  zone_id = data.aws_route53_zone.main.zone_id
  count   = var.instance_count
  name    = "kafka${count.index + 1}.katruk.ru"
  type    = "A"
  ttl     = "300"
  records = ["${element(aws_instance.amazon.*.public_ip, count.index)}"]
}


# TODO

data "aws_instance" "ip1" {
  instance_tags = {
    Name = "kafka-1"
  }
    depends_on = [aws_instance.amazon]
}

data "aws_instance" "ip2" {
  instance_tags = {
    Name = "kafka-2"
  }
    depends_on = [aws_instance.amazon]
}

data "aws_instance" "ip3" {
  instance_tags = {
    Name = "kafka-3"
  }
    depends_on = [aws_instance.amazon]
}

data "template_file" "zookeper_properties_template" {
  template = "${file("terraform_templates/zookeeper.properties.j2")}"
  vars = {
    host1_ip = "${data.aws_instance.ip1.private_ip}"
    host2_ip = "${data.aws_instance.ip2.private_ip}"
    host3_ip = "${data.aws_instance.ip3.private_ip}"
  }
}

data "template_file" "kafka_properties_template1" {
  template = "${file("terraform_templates/kafka-properties1.j2")}"
  vars = {
    host1_ip = "${data.aws_instance.ip1.private_ip}"
    host2_ip = "${data.aws_instance.ip2.private_ip}"
    host3_ip = "${data.aws_instance.ip3.private_ip}"
  }
}

data "template_file" "kafka_properties_template2" {
  template = "${file("terraform_templates/kafka-properties2.j2")}"
  vars = {
    host1_ip = "${data.aws_instance.ip1.private_ip}"
    host2_ip = "${data.aws_instance.ip2.private_ip}"
    host3_ip = "${data.aws_instance.ip3.private_ip}"
  }
}

data "template_file" "kafka_properties_template3" {
  template = "${file("terraform_templates/kafka-properties3.j2")}"
  vars = {
    host1_ip = "${data.aws_instance.ip1.private_ip}"
    host2_ip = "${data.aws_instance.ip2.private_ip}"
    host3_ip = "${data.aws_instance.ip3.private_ip}"
  }
}

resource "null_resource" "del_ansible_vars" {
  provisioner "local-exec" {
    command = "./terraform_templates/delete_files.sh"
  }
    depends_on = [aws_instance.amazon]
}

resource "local_file" "group_vars_template1" {
    content     = data.template_file.kafka_properties_template1.rendered
    filename = "roles/kafka/templates/kafka1-properties.j2" 
  }

resource "local_file" "group_vars_template2" {
    content     = data.template_file.kafka_properties_template2.rendered
    filename = "roles/kafka/templates/kafka2-properties.j2" 
  }

resource "local_file" "group_vars_template3" {
    content     = data.template_file.kafka_properties_template3.rendered
    filename = "roles/kafka/templates/kafka3-properties.j2" 
  }

resource "null_resource" "run_ansible_cluster" {
  provisioner "local-exec" {
    command = "ansible-playbook kafka_cluster.yaml -b"
  }
    depends_on = [aws_route53_record.kafka]
}