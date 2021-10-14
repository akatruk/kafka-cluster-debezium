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
    key_name                = aws_key_pair.my_key.id
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

data "aws_instance" "ip" {
  instance_tags = {
    name = "kafka"
  }
    depends_on = [aws_instance.amazon]
}

# data "aws_instance" "ip" {
#   instance_tags = {
#     name = "kafka"
#   }
#     depends_on = [aws_instance.amazon]
# }

# data "aws_instance" "ip" {
#   instance_tags = {
#     name = "kafka"
#   }
#     depends_on = [aws_instance.amazon]
# }

data "template_file" "group_vars_template" {
  template = "${file("terraform_templates/group_vars_template")}"
  vars = {
    host1_ip = "${data.aws_instance.ip.private_ip}"
  }
}

resource "local_file" "group_vars_template" {
    content     = data.template_file.group_vars_template.rendered
    filename = "group_vars/all.yml"
}

# resource "local_file" "key" {
#   filename = "ips.txt"
#   content  = "${aws_instance.amazon[*].public_ip}"
# }
