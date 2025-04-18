# Variables
variable "region" {
  default = "ap-south-1"
}

variable "cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_key_path" {
  description = "Path to the public key file"
  default     = "/home/codespace/.ssh/id_rsa.pub"
}

variable "availability_zone" {
  default = "ap-south-1a"
}

variable "subnet_cidr" {
  default = "10.0.0.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  default     = "0.0.0.0/0"  # Change this to your IP for better security
}

# Provider
provider "aws" {
  region = var.region
}

# AWS Key Pair
resource "aws_key_pair" "example" {
  key_name   = "EC2-key-pair-for-terraform"
  public_key = file(var.public_key_path)
}

# VPC
resource "aws_vpc" "vpc-for-terraform" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Subnet
resource "aws_subnet" "subnet-for-terraform" {
  vpc_id                  = aws_vpc.vpc-for-terraform.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
}

# Internet Gateway
resource "aws_internet_gateway" "igw-for-terraform" {
  vpc_id = aws_vpc.vpc-for-terraform.id
}

# Route Table
resource "aws_route_table" "RT-for-terraform" {
  vpc_id = aws_vpc.vpc-for-terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-for-terraform.id
  }
}

# Route Table Association
resource "aws_route_table_association" "rta-for-terraform" {
  subnet_id      = aws_subnet.subnet-for-terraform.id
  route_table_id = aws_route_table.RT-for-terraform.id
}

# Security Group
resource "aws_security_group" "Sg-for-terraform" {
  name   = "Sg-for-terraform"
  vpc_id = aws_vpc.vpc-for-terraform.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Sg-for-terraform"
  }
}

# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]  # Canonical
}

# EC2 Instance
resource "aws_instance" "EC2-Ubuntu-for-terraform" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.Sg-for-terraform.id]
  subnet_id              = aws_subnet.subnet-for-terraform.id

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y python3-pip
    sudo pip3 install flask
    echo 'from flask import Flask\napp = Flask(__name__)\n@app.route("/")\ndef hello():\n    return "Hello, Chintan Boghara from Terraform!"\nif __name__ == "__main__":\n    app.run(host="0.0.0.0", port=80)' > /home/ubuntu/app.py
    cd /home/ubuntu
    sudo nohup python3 app.py &
    EOF
}

# Output
output "instance_public_ip" {
  value = aws_instance.EC2-Ubuntu-for-terraform.public_ip
}
