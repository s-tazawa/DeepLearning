provider "aws" {
  region = "${var.region}"
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${tls_private_key.keygen.public_key_openssh}"
}

resource "aws_vpc" "k8s_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.k8s_vpc.id}"
}

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.k8s_vpc.id}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr, 8, 1)}"
  availability_zone       = "${var.az}"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.k8s_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.public.id}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_network_acl" "acl" {
  vpc_id     = "${aws_vpc.k8s_vpc.id}"
  subnet_ids = ["${aws_subnet.public.id}"]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_security_group" "k8s_master" {
  name        = "k8s_master_sg"
  vpc_id      = "${aws_vpc.k8s_vpc.id}"
  description = "k8s_master_sg"
}

resource "aws_security_group_rule" "kubernetes-api-server" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.k8s_vpc.cidr_block]
  security_group_id = "${aws_security_group.k8s_master.id}"
  description = "kubernetes-api-server"
}

resource "aws_security_group_rule" "etcd-server" {
  type              = "ingress"
  from_port         = 2739
  to_port           = 2380
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.k8s_vpc.cidr_block]
  security_group_id = "${aws_security_group.k8s_master.id}"
  description = "etcd-server"
}

resource "aws_security_group_rule" "master-kubelet-api" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.k8s_vpc.cidr_block]
  security_group_id = "${aws_security_group.k8s_master.id}"
  description = "master-kubelet-api"
}

resource "aws_security_group_rule" "kube-scheduler" {
  type              = "ingress"
  from_port         = 10251
  to_port           = 10251
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.k8s_vpc.cidr_block]
  security_group_id = "${aws_security_group.k8s_master.id}"
  description = "kube-scheduler"
}

resource "aws_security_group_rule" "kube-controller-manager" {
  type              = "ingress"
  from_port         = 10252
  to_port           = 10252
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.k8s_vpc.cidr_block]
  security_group_id = "${aws_security_group.k8s_master.id}"
  description = "kube-controller-manager"
}

resource "aws_security_group_rule" "master_allow_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [aws_vpc.k8s_vpc.cidr_block]
  # prefix_list_ids   = [aws_vpc_endpoint.my_endpoint.prefix_list_id]
  security_group_id = "${aws_security_group.k8s_worker.id}"
  description = "master_allow_all"
}

resource "aws_security_group" "k8s_worker" {
  name        = "k8s_worker_sg"
  vpc_id      = "${aws_vpc.k8s_vpc.id}"
  description = "k8s_worker_sg"
}

resource "aws_security_group_rule" "worker-kubelet-api" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.k8s_vpc.cidr_block]
  security_group_id = "${aws_security_group.k8s_worker.id}"
    description = "worker-kubelet-api"

}

resource "aws_security_group_rule" "nordport-services" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.k8s_vpc.cidr_block]
  security_group_id = "${aws_security_group.k8s_worker.id}"
  description = "nordport-services"

}

resource "aws_security_group_rule" "worker_allow_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [aws_vpc.k8s_vpc.cidr_block]
  # prefix_list_ids   = [aws_vpc_endpoint.my_endpoint.prefix_list_id]
  security_group_id = "${aws_security_group.k8s_worker.id}"
  description = "worker_allow_all"

}


data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }
}

resource "aws_instance" "k8s-master" {
  count = "${ length( var.master ) }"
  # ami                    = "${data.aws_ami.amazon_linux.id}"
  ami                    = "${element(var.master, count.index)}"
  instance_type          = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.k8s_master.id}"]
  subnet_id              = "${aws_subnet.public.id}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = true
  tags                        = { Name = "${element(var.master, count.index)}" }

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }
}

resource "aws_instance" "k8s-worker" {
  count = "${ length( var.worker ) }"
  # ami                    = "${data.aws_ami.amazon_linux.id}"
  ami                    = "${data.aws_ami.amazon_linux.id}"
  instance_type          = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.k8s_worker.id}"]
  subnet_id              = "${aws_subnet.public.id}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = true
  tags                        = { Name = "${element(var.worker, count.index)}" }

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }
}
