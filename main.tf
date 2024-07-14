provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc-app-a" {
  cidr_block        = "10.0.0.0/23"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-app-a"
  }
}

resource "aws_vpc" "vpc-app-b" {
  cidr_block        = "10.0.2.0/23"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-app-b"
  }
}

resource "aws_vpc" "vpc-client" {
  cidr_block        = "10.0.4.0/23"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-client"
  }
}

resource "aws_internet_gateway" "igw-vpc-app-a" {
  vpc_id = aws_vpc.vpc-app-a.id

  tags = {
    Name = "InternetGateway-vpc-app-a"
  }
}

resource "aws_internet_gateway" "igw-vpc-app-b" {
  vpc_id = aws_vpc.vpc-app-b.id

  tags = {
    Name = "InternetGateway-vpc-app-b"
  }
}

resource "aws_internet_gateway" "igw-vpc-client" {
  vpc_id = aws_vpc.vpc-client.id

  tags = {
    Name = "InternetGateway-vpc-client"
  }
}

resource "aws_subnet" "public_subnet-vpc-a" {
  vpc_id                  = aws_vpc.vpc-app-a.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-vpc-a"
  }
}

resource "aws_subnet" "public_subnet-vpc-b" {
  vpc_id                  = aws_vpc.vpc-app-b.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-vpc-b"
  }
}

resource "aws_subnet" "public_subnet-vpc-client" {
  vpc_id                  = aws_vpc.vpc-client.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-vpc-client"
  }
}

resource "aws_route" "default_route-vpc-app-a" {
  route_table_id          = aws_vpc.vpc-app-a.default_route_table_id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.igw-vpc-app-a.id
}

resource "aws_route" "default_route-vpc-app-b" {
  route_table_id          = aws_vpc.vpc-app-b.default_route_table_id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.igw-vpc-app-b.id
}

resource "aws_route" "default_route-vpc-client" {
  route_table_id          = aws_vpc.vpc-client.default_route_table_id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.igw-vpc-client.id
}

resource "aws_security_group" "instance_sg-vpc-app-a" {
  vpc_id = aws_vpc.vpc-app-a.id

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
    Name = "instance-sg-vpc-app-a"
  }
}

resource "aws_security_group" "instance_sg-vpc-app-b" {
  vpc_id = aws_vpc.vpc-app-b.id

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
    Name = "instance-sg-vpc-app-b"
  }
}

resource "aws_security_group" "instance_sg-vpc-client" {
  vpc_id = aws_vpc.vpc-client.id

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
    Name = "instance-sg-vpc-client"
  }
}

resource "aws_instance" "ec2_instance-vpc-a" {
  ami                       = "ami-0b72821e2f351e396" 
  instance_type             = "t2.micro"
  subnet_id                 = aws_subnet.public_subnet-vpc-a.id
  vpc_security_group_ids    = [ aws_security_group.instance_sg-vpc-app-a.id ]
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
              echo "Hello World from Public Instance vpc-app-a" > /var/www/html/index.html
              EOF

  depends_on = [aws_security_group.instance_sg-vpc-app-a]

  tags = {
    Name = "ec2-instance-vpc-app-a"
  }
}

resource "aws_instance" "ec2_instance-vpc-b" {
  ami                       = "ami-0b72821e2f351e396" 
  instance_type             = "t2.micro"
  subnet_id                 = aws_subnet.public_subnet-vpc-b.id
  vpc_security_group_ids    = [ aws_security_group.instance_sg-vpc-app-b.id ]
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
              echo "Hello World from Public Instance vpc-app-b" > /var/www/html/index.html
              EOF

  depends_on = [aws_security_group.instance_sg-vpc-app-b]

  tags = {
    Name = "ec2-instance-vpc-app-b"
  }
}

resource "aws_instance" "ec2_instance-vpc-client" {
  ami                       = "ami-0b72821e2f351e396" 
  instance_type             = "t2.micro"
  subnet_id                 = aws_subnet.public_subnet-vpc-client.id
  vpc_security_group_ids    = [ aws_security_group.instance_sg-vpc-client.id ]
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
              echo "Hello World from Public Instance vpc-client" > /var/www/html/index.html
              EOF

  depends_on = [aws_security_group.instance_sg-vpc-client]

  tags = {
    Name = "ec2-instance-vpc-client"
  }
}