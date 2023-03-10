terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "my_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "my_rta" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_rt.id
}

resource "aws_security_group" "my_sg" {
  name_prefix = "example-sg"
  vpc_id = aws_vpc.my_vpc.id

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
  
    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my_instance" {
  ami           = "ami-005e54dee72cc1d00"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update
                sudo apt-get install nginx -y
                sudo apt install unzip
                sudo systemctl start nginx
                sudo systemctl enable nginx
                sudo ufw allow 'Nginx HTTP'
                sudo ufw allow 'Nginx HTTPS'
                wget https://github.com/shing963578/CV/raw/main/My_cv.zip
                sudo unzip -o My_cv.zip
                sudo systemctl restart nginx
              EOF

  tags = {
    Name = "my-instance"
  }
}