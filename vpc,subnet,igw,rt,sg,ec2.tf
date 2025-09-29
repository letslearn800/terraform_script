#CREATING PROVIDER----------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Change region if needed
}

#CREATING VPC-----------------------------------
resource "aws_vpc" "prem-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "prem-vpc"
  }
}

#CREATING PUBLIC-SUBNET-----------------------------------
resource "aws_subnet" "prem-public-subnet" {
  vpc_id                  = aws_vpc.prem-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true        #Enable public ip for ec2 instance.
  tags = {
    Name = "prem-public-subnet"
  }
}

#CREATING IGW-----------------------------------
resource "aws_internet_gateway" "prem-IGW" {
  vpc_id = aws_vpc.prem-vpc.id

  tags = {
    Name = "prem-IGW"
  }
}

#CREATING ROUTE-TABLE-----------------------------------
resource "aws_route_table" "prem-rt" {
  vpc_id = aws_vpc.prem-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prem-IGW.id
  }

  tags = {
    Name = "prem-RT"
  }
}

#CREATING ASSOCIATION-----------------------------------
resource "aws_route_table_association" "RT-subnet-association" {
  subnet_id      = aws_subnet.prem-public-subnet.id
  route_table_id = aws_route_table.prem-rt.id
}

#CREATING SECURITY_GROUP-----------------------------------
resource "aws_security_group" "prem-SG" {
  name        = "prem-SG"
  description = "Allow https http ssh"
  vpc_id      = aws_vpc.prem-vpc.id

  ingress {
    description      = "https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "0"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "prem-SG"
  }
}

#CREATING EC2-INSTANCE-----------------------------------
resource "aws_instance" "prem-ec2-instance" {
  ami               = "ami-08982f1c5bf93d976"
  instance_type     = "t3.micro"
  availability_zone = "us-east-1a"
  subnet_id         = aws_subnet.prem-public-subnet.id
  security_groups   = [aws_security_group.prem-SG.id]
  tags = {
    Name = "prem-ec2-instance"
  }
}


------------------------- Attached extra volume in ec2--------------------------

# CREATING EC2 UBUNTU-SERVER ----------------------------
resource "aws_instance" "jenkins-EC2" {
  ami                    = "ami-0360c520857e3138f"
  instance_type          = "m7i-flex.large"
  key_name               = "Universal_keys"
  vpc_security_group_ids = [aws_security_group.prem_sg.id]
  user_data              = templatefile("./script.sh", {})

  tags = {
    Name = "jenkins-sonarqube"
  }

  root_block_device {
    volume_size = 30
  }
}
