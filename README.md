# Terraform AWS EC2 with Flask App

This repository contains a Terraform configuration to deploy an EC2 instance on AWS running a simple Flask application. The app displays the message "Hello, Chintan Boghara from Terraform!" when accessed via a web browser.

## Prerequisites

Before you begin, ensure the following are in place:

- **AWS Account**: You need an AWS account with permissions to create VPCs, subnets, EC2 instances, and other related resources.
- **AWS CLI**: Installed and configured with your credentials. Run the following command to set it up:
  ```bash
  aws configure
  ```
- **Terraform**: Installed on your local machine. Download it from [terraform.io](https://www.terraform.io/downloads.html) if needed.
- **SSH Key Pair**: An SSH key pair for secure access to the EC2 instance. The Terraform script assumes:
  - Public key at `/home/codespace/.ssh/id_rsa.pub`
  - Private key at `/home/codespace/.ssh/id_rsa`
  
  If your keys are stored elsewhere, update the `file()` paths in the `aws_key_pair` and `connection` blocks of the Terraform script.
- **Flask App File**: The `app.py` file (provided below) must be present in the same directory as the Terraform files.

### Flask Application (`app.py`)
The following code should be saved as `app.py` in your working directory:
```python
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello, Chintan Boghara from Terraform!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
```

## Setup

Follow these steps to deploy the infrastructure and Flask application:

1. **Navigate to the Directory**  
   Open a terminal and change to the directory containing the Terraform files and `app.py`.

2. **Initialize Terraform**  
   This downloads the necessary provider plugins:
   ```bash
   terraform init
   ```

3. **Review the Planned Changes**  
   Check what Terraform will create:
   ```bash
   terraform plan
   ```

4. **Apply the Configuration**  
   Deploy the infrastructure:
   ```bash
   terraform apply
   ```
   When prompted, type `yes` to confirm.

5. **Access the Application**  
   After the apply completes, Terraform will display the EC2 instance’s public IP in the output (assuming an output is defined, see Notes below). For example:
   ```
   Outputs:

   instance_public_ip = "<EC2_PUBLIC_IP>"
   ```
   Open your browser and visit `http://<EC2_PUBLIC_IP>` to see the greeting message.  
   *If no output is defined, you can find the public IP in the AWS Management Console under EC2 > Instances.*

## Cleanup

To delete all resources created by this Terraform configuration:
```bash
terraform destroy
```
When prompted, type `yes` to confirm.

## Notes

- **Region**: The script is configured for the `ap-south-1` region. To use a different region, update the `region` in the `provider "aws"` block and ensure the AMI ID (`ami-053b12d3152c0cc71`) matches an Ubuntu AMI available in that region.
- **Security Group**: The configuration allows HTTP (port 80) and SSH (port 22) traffic from anywhere (`0.0.0.0/0`). For production use, restrict SSH access to specific IP ranges for better security.
- **Output**: To make the public IP easily accessible, consider adding this to your Terraform script:
  ```hcl
  output "instance_public_ip" {
    value = aws_instance.EC2-Ubuntu-for-terraform.public_ip
  }
  ```
  This ensures the IP is displayed after `terraform apply`.

## Infrastructure Overview

The Terraform script provisions:
- **VPC**: A Virtual Private Cloud with CIDR block `10.0.0.0/16`.
- **Subnet**: A public subnet (`10.0.0.0/24`) in `ap-south-1a` with auto-assigned public IPs.
- **Internet Gateway**: Enables internet access for the VPC.
- **Route Table**: Routes traffic from the subnet to the internet.
- **Security Group**: Permits inbound HTTP (port 80) and SSH (port 22) traffic.
- **EC2 Instance**: A `t2.micro` instance running Ubuntu, with Flask installed and the app running on port 80.
