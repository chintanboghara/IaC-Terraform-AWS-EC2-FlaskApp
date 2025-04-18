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
  
  If your public key is stored elsewhere, update the `public_key_path` variable in `terraform.tfvars` or via command-line flags.
- **Variables**: You can customize the deployment by setting variables such as `region`, `cidr`, `availability_zone`, and `allowed_ssh_cidr`. For better security, set `allowed_ssh_cidr` to your specific IP range.

## Setup

Follow these steps to deploy the infrastructure and Flask application:

1. **Navigate to the Directory**  
   Open a terminal and change to the directory containing the Terraform files.

2. **Customize Variables (Optional)**  
   You can customize the deployment by creating a `terraform.tfvars` file or using command-line flags. For example, to restrict SSH access to your IP:
   ```hcl
   allowed_ssh_cidr = "YOUR_IP/32"
   ```
   Replace `YOUR_IP` with your actual IP address.

3. **Initialize Terraform**  
   This downloads the necessary provider plugins:
   ```bash
   terraform init
   ```

4. **Review the Planned Changes**  
   Check what Terraform will create:
   ```bash
   terraform plan
   ```

5. **Apply the Configuration**  
   Deploy the infrastructure:
   ```bash
   terraform apply
   ```
   When prompted, type `yes` to confirm.

## Access the Application

After the apply completes, Terraform will display the EC2 instance’s public IP in the output:
```
Outputs:

instance_public_ip = "<EC2_PUBLIC_IP>"
```
Open your browser and visit `http://<EC2_PUBLIC_IP>` to see the greeting message.

## Cleanup

To delete all resources created by this Terraform configuration:
```bash
terraform destroy
```
When prompted, type `yes` to confirm.

## Notes

- **Dynamic AMI Selection**: The configuration uses a data source to fetch the latest Ubuntu 20.04 AMI, ensuring your instance always runs on an up-to-date image.
- **User Data**: The Flask app is set up using the `user_data` attribute, which is more reliable and efficient than provisioners.
- **Security**: The SSH ingress rule is restricted to the CIDR block specified in `allowed_ssh_cidr`. For production use, set this to your specific IP range.
- **Customization**: You can customize variables like `region`, `cidr`, and `availability_zone` by setting them in a `terraform.tfvars` file or via command-line flags.
