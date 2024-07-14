provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  count             = 3
  cidr_block        = "10.0.${count.index * 10}.0/23"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  count = 3

  vpc_id = element(aws_vpc.vpc.*.id, count.index)

  tags = {
    Name = "InternetGateway-${count.index + 1}"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = 3
  vpc_id                  = element(aws_vpc.vpc.*.id, count.index)
  cidr_block              = "10.0.${count.index * 10}.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_route" "default_route" {
  count                   = 3
  route_table_id          = element(aws_vpc.vpc.*.default_route_table_id, count.index)
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = element(aws_internet_gateway.igw.*.id, count.index)
}

resource "aws_security_group" "instance_sg" {
  count  = 3
  vpc_id = element(aws_vpc.vpc.*.id, count.index)

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-sg-${count.index + 1}"
  }
}

resource "aws_instance" "ec2_instance" {
  count                     = 3
  ami                       = "ami-0b72821e2f351e396" 
  instance_type             = "t2.micro"
  subnet_id                 = element(aws_subnet.public_subnet.*.id, count.index)
  vpc_security_group_ids    = [element(aws_security_group.instance_sg.*.id, count.index)]
  associate_public_ip_address = true

    user_data = <<-EOF
              #!/bin/bash
              yum update -y
              sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
              systemctl restart sshd
              service sshd restart
              echo "12qwaszx" | passwd --stdin ec2-user
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello World from Public Instance ${count.index + 1}" > /var/www/html/index.html
              EOF

  depends_on = [aws_security_group.instance_sg]

  tags = {
    Name = "ec2-instance-${count.index + 1}"
  }
}