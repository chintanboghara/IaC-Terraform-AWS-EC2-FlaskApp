## Explanation of the Code:

This Terraform script automates the provisioning of infrastructure in AWS with a simple Flask application running on an EC2 instance.

1. **Provider Configuration:**
   ```hcl
   provider "aws" {
     region = "ap-south-1"
   }
   ```
   - Configures the AWS provider to interact with the AWS resources in the `ap-south-1` region.

2. **CIDR Variable:**
   ```hcl
   variable "cidr" {
     default = "10.0.0.0/16"
   }
   ```
   - Defines a variable `cidr` that holds the IP range for the VPC (Virtual Private Cloud). This is a `10.0.0.0/16` subnet, providing a large number of IP addresses for the VPC.

3. **AWS Key Pair:**
   ```hcl
   resource "aws_key_pair" "example" {
     key_name   = "EC2-key-pair-for-terraform"
     public_key = file("/home/codespace/.ssh/id_rsa.pub")
   }
   ```
   - Creates an SSH key pair (`EC2-key-pair-for-terraform`) and uploads the public key to AWS. It uses the local SSH public key for secure EC2 login.

4. **VPC (Virtual Private Cloud):**
   ```hcl
   resource "aws_vpc" "vpc-for-terraform" {
     cidr_block = var.cidr
   }
   ```
   - Creates a VPC using the `cidr` range defined earlier (`10.0.0.0/16`).

5. **Subnet:**
   ```hcl
   resource "aws_subnet" "subnet-for-terraform" {
     vpc_id                  = aws_vpc.vpc-for-terraform.id
     cidr_block              = "10.0.0.0/24"
     availability_zone       = "ap-south-1a"
     map_public_ip_on_launch = true
   }
   ```
   - Creates a subnet (`10.0.0.0/24`) within the VPC in availability zone `ap-south-1a`. It also ensures that public IP addresses are assigned to instances launched in this subnet.

6. **Internet Gateway:**
   ```hcl
   resource "aws_internet_gateway" "igw-for-terraform" {
     vpc_id = aws_vpc.vpc-for-terraform.id
   }
   ```
   - Creates an Internet Gateway (`igw-for-terraform`) to provide Internet access to the resources in the VPC.

7. **Route Table:**
   ```hcl
   resource "aws_route_table" "RT-for-terraform" {
     vpc_id = aws_vpc.vpc-for-terraform.id

     route {
       cidr_block = "0.0.0.0/0"
       gateway_id = aws_internet_gateway.igw-for-terraform.id
     }
   }
   ```
   - Creates a route table and adds a default route (0.0.0.0/0) that points to the Internet Gateway for internet access.

8. **Route Table Association:**
   ```hcl
   resource "aws_route_table_association" "rta-for-terraform" {
     subnet_id      = aws_subnet.subnet-for-terraform.id
     route_table_id = aws_route_table.RT-for-terraform.id
   }
   ```
   - Associates the route table with the subnet, ensuring that the subnet has internet access.

9. **Security Group:**
   ```hcl
   resource "aws_security_group" "Sg-for-terraform" {
     name   = "Sg-for-terraform"
     vpc_id = aws_vpc.vpc-for-terraform.id

     ingress {
       description = "HTTP from VPC"
       from_port   = 80
       to_port     = 80
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
     }

     ingress {
       description = "SSH"
       from_port   = 22
       to_port     = 22
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
       Name = "Sg-for-terraform"
     }
   }
   ```
   - Creates a security group allowing inbound HTTP (port 80) and SSH (port 22) access from anywhere (`0.0.0.0/0`). It also allows all outbound traffic.

10. **EC2 Instance:**
    ```hcl
    resource "aws_instance" "EC2-Ubuntu-for-terraform" {
      ami                    = "ami-053b12d3152c0cc71"
      instance_type          = "t2.micro"
      key_name               = aws_key_pair.example.key_name
      vpc_security_group_ids = [aws_security_group.Sg-for-terraform.id]
      subnet_id              = aws_subnet.subnet-for-terraform.id

      connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = file("/home/codespace/.ssh/id_rsa")
        host        = self.public_ip
      }

      provisioner "file" {
        source      = "app.py"
        destination = "/home/ubuntu/app.py"
      }

      provisioner "remote-exec" {
        inline = [
          "sudo apt update -y",
          "sudo apt install -y python3-pip",
          "sudo pip3 install flask",
          "cd /home/ubuntu",
          "sudo python3 app.py &",
        ]
      }
    }
    ```
    - Creates an EC2 instance with the Ubuntu AMI (`ami-053b12d3152c0cc71`), with the security group and subnet configured.
    - Uses the provisioners `file` and `remote-exec` to transfer the Flask app and run it on the EC2 instance after installing dependencies.

11. **Flask Application (`app.py`):**
    ```python
    from flask import Flask

    app = Flask(__name__)

    @app.route("/")
    def hello():
        return "Hello, Chintan Boghara from Terraform!"

    if __name__ == "__main__":
        app.run(host="0.0.0.0", port=80)
    ```
    - A simple Flask app that returns a greeting message when accessed via HTTP.

This repository contains Terraform configuration to deploy an EC2 instance on AWS running a simple Flask application. The app returns a greeting message when accessed from the browser.


## Setup

1. Configure AWS credentials:
   Ensure that your AWS credentials are configured. You can set them using the AWS CLI:
   ```bash
   aws configure
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the planned changes:
   ```bash
   terraform plan
   ```

5. Apply the Terraform configuration:
   ```bash
   terraform apply
   ```

6. After Terraform has completed, you can access the Flask app via the public IP of the EC2 instance. It will be printed in the output:
   ```
   Public IP: <EC2_PUBLIC_IP>
   ```

   Visit the URL `http://<EC2_PUBLIC_IP>` in your browser to see the greeting message.

## Cleanup

To remove the resources created by this Terraform configuration:
```bash
terraform destroy
```