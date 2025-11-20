# TechCorp AWS Infrastructure - Terraform Deployment

## Overview

This project deploys a highly available web application infrastructure on AWS using
Terraform, designed to meet TechCorp's business requirements for a new web
application launch. The infrastructure provides secure, scalable, and highly available
architecture with proper network isolation and load balancing capabilities.

## Architecture

```
-VPC: 10.0.0.0/16 CIDR block with DNS hostnames and DNS support enabled
- Subnets:
  - 2 Public subnets (10.0.1.0/24, 10.0.2.0/24) across 2 availability zones
  - 2 Private subnets (10.0.3.0/24, 10.0.4.0/24) across 2 availability zones
- EC2 Instances:
  - 1 Bastion host (t3.micro) in public subnet with Elastic IP
  - 2 Web servers (t3.micro) in private subnets running Apache
  -1 Database server (t3.small) in private subnet running PostgreSQL
- Load Balancer: Application Load Balancer distributing traffic to web servers
- Networking: Internet Gateway, NAT Gateways, and route tables
- Security: Security groups following principle of least privilege
```
## Project Structure

```
terraform-assessment/
├── main.tf # Main Terraform configuration
├── variables.tf # Variable declarations
├── outputs.tf # Output definitions
├── terraform.tfvars.example # Example variable values
├── user_data/
│ ├── web_server_setup.sh # Apache installation and configuration
│ └── db_server_setup.sh # PostgreSQL installation and configuration
├── evidence/ # Deployment evidence screenshots
│ ├── terraform-plan.png


│ ├── terraform-apply.png
│ ├── aws-resources.png
│ ├── alb-web-server-1.png
│ ├── alb-web-server-2.png
│ ├── ssh-bastion.png
│ ├── ssh-web-server-1.png
│ ├── ssh-web-server-2.png
│ ├── ssh-db-server.png
│ └── postgres-connection.png
└── README.md # This documentation
```
## Prerequisites

### Required Tools

```
- Terraform (version 1.0 or later)
- AWS CLI configured with valid credentials
- Bash shell (Linux/macOS) or Git Bash (Windows)
```
### AWS IAM Permissions

Your IAM user/role must have permissions to create:
- VPC and networking components (VPC, subnets, route tables, Internet Gateway,
NAT Gateway)
- EC2 instances and Elastic IPs
- Application Load Balancers and target groups
- Security groups
- IAM roles (if applicable)

### AWS Resources

```
- SSH Key Pair created in AWS EC2 Console
- Your Public IP Address for bastion host access
```

## Deployment Instructions

### Step 1: Clone and Setup

bash
git clone https://github.com/yourusername/month-one-assessment.git
cd month-one-assessment

### Step 2: Configure Variables

1. Copy the example variables file:
2. bash
3. cp terraform.tfvars.example terraform.tfvars
4. Edit terraform.tfvars with your specific values:
5. hcl
region = "us-east-1"
public_key_name = "your-keypair-name" _# Your AWS key pair name_
web_instance_type = "t3.micro"
db_instance_type = "t3.small"
6. my_ip_address = "YOUR_IP_ADDRESS/32" _# Your current public IP_
7. Get your public IP address:
8. bash
9. curl ifconfig.me

### Step 3: Initialize Terraform

bash
terraform init
This downloads the required AWS provider plugins and sets up the backend.


### Step 4: Validate Configuration

bash
terraform validate
Validates the Terraform configuration files for syntax and configuration errors.

### Step 5: Review Deployment Plan

bash
terraform plan
Review the execution plan showing all resources that will be created. Take a screenshot
of this output for your submission evidence.

### Step 6: Deploy Infrastructure

bash
terraform apply
Type yes when prompted to confirm the deployment.
⏱ Expected Deployment Time: 5-10 minutes
Take a screenshot of the successful completion message for your evidence folder.

### Step 7: Retrieve Output Information

bash
terraform output
This displays critical information including:
- VPC ID
- Load Balancer DNS name


```
- Bastion host public IP
- SSH access commands
```
## Accessing the Infrastructure

### Web Application Access

1. Get the Load Balancer DNS name:
2. bash
3. terraform output load_balancer_dns_name
4. Access the web application in your browser:
5. text
6. [http://<load-balancer-dns-name>](http://<load-balancer-dns-name>)
7. Refresh the page multiple times to see traffic being distributed between the two
    web servers (different instance IDs should appear)

### Bastion Host Access

bash
ssh -i /path/to/your-key.pem ec2-user@<bastion-public-ip>

### Accessing Private Instances via Bastion

**Option 1: Direct Jump Host (Recommended)**
bash
_# Access Web Server 1_
ssh -i /path/to/your-key.pem -J ec2-user@<bastion-ip>
ec2-user@<web-server-1-private-ip>
_# Access Web Server 2_
ssh -i /path/to/your-key.pem -J ec2-user@<bastion-ip>
ec2-user@<web-server-2-private-ip>


_# Access Database Server_
ssh -i /path/to/your-key.pem -J ec2-user@<bastion-ip>
ec2-user@<db-server-private-ip>
**Option 2: Manual Two-Step Process**
bash
_# Step 1: Connect to bastion_
ssh -i /path/to/your-key.pem ec2-user@<bastion-public-ip>
_# Step 2: Copy SSH key to bastion (from your local machine)_
scp -i /path/to/your-key.pem /path/to/your-key.pem ec2-user@<bastion-ip>:~/
_# Step 3: Access private instances from bastion_
ssh -i ~/your-key.pem ec2-user@<private-instance-ip>

### Database Access

1. SSH to the database server via the bastion host
2. Connect to PostgreSQL:
3. bash
4. sudo -u postgres psql
5. Verify database connectivity:
6. sql
\l _-- List all databases_
\conninfo _-- Show connection information_
CREATE DATABASE techcorp_db; _-- Create a test database_
\c techcorp_db _-- Connect to the database_
7. \q _-- Exit PostgreSQL_

## User Data Scripts


### web_server_setup.sh

```
- Installs and configures Apache HTTP server
- Enables and starts the httpd service
- Creates a custom HTML page displaying the instance ID for verification
- Configures the web server to start on boot
```
### db_server_setup.sh

```
- Installs PostgreSQL database server
- Initializes the database cluster
- Starts and enables PostgreSQL service
- Configures basic PostgreSQL settings
- Ensures service starts automatically on system boot
```
## Verification Checklist

```
- VPC created with correct CIDR block and DNS settings
- All subnets created in appropriate availability zones
- 4 EC2 instances running (1 bastion, 2 web, 1 database)
- Application Load Balancer active and healthy
- Web application accessible via load balancer DNS
- Load balancer distributing traffic between both web servers
- SSH access to bastion host from authorized IP
- SSH access to web servers via bastion host
- SSH access to database server via bastion host
- PostgreSQL running and accessible on database server
- All security groups properly configured
- NAT Gateways providing internet access to private instances
- Route tables correctly configured
```
## Troubleshooting

### Common Issues and Solutions


Cannot SSH to Bastion Host
```
- Verify your IP address hasn't changed: curl ifconfig.me
- Update the security group or re-run terraform apply with the new IP
- Check that the key pair name is correct in your variables
Load Balancer Not Accessible
- Wait 2-3 minutes for instances to pass health checks
- Check target group health status in AWS Console
- Verify security groups allow HTTP traffic (port 80)
- Ensure web servers are running Apache correctly
Web Servers Not Responding
- SSH to web servers and check Apache status:
- bash
- sudo systemctl status httpd
- Check user data execution logs:
- bash
- sudo cat /var/log/cloud-init-output.log
- Verify Apache is listening on port 80:
- bash
- sudo netstat -tlnp | grep :
Database Connection Issues
- Verify PostgreSQL is running:
- bash
- sudo systemctl status postgresql
- Check PostgreSQL listening configuration:
- bash
- sudo -u postgres psql -c "SHOW listen_addresses;"
- Manually install PostgreSQL if user data failed:
- bash
sudo yum install -y postgresql-server postgresql-contrib
sudo postgresql-setup initdb
sudo systemctl start postgresql

```
- sudo systemctl enable postgresql
```
## Cleanup Instructions

### Destroy Infrastructure

bash
terraform destroy
Type yes when prompted to confirm deletion of all resources.
⚠ Critical Warning:
- This action is irreversible and will permanently delete ALL AWS resources
- NAT Gateways incur hourly costs - ensure destruction when not in use
- Save all necessary data and evidence before proceeding

### Post-Destruction Verification

1. Check AWS Management Console to confirm all resources are deleted
2. Verify no lingering resources that might incur costs:
    ○ EC2 instances (bastion, web servers, database)
    ○ Load balancers and target groups
    ○ NAT Gateways and Elastic IPs
    ○ VPC components (subnets, route tables, Internet Gateway)

## Security Best Practices

### Data Protection

```
- Never commit sensitive data to version control
- Exclude terraform.tfvars with real values from commits
- Never commit .pem private key files
- Keep terraform.tfstate files secure and never commit them
```

### Access Control

```
- Restrict SSH access to bastion host from your IP only
- Use SSH key-based authentication instead of passwords
- Regularly rotate credentials and keys
- Implement multi-factor authentication for AWS console
```
### Network Security

```
- Web and database servers reside in private subnets
- Only bastion host is publicly accessible
- Security groups follow principle of least privilege
- Database only accessible from web server security group
```
## Cost Management

### Cost Considerations

```
- NAT Gateways: incur hourly charges + data processing fees
- EC2 Instances: t3.micro/t3.small instances have hourly costs
- Load Balancer: Application Load Balancers have hourly charges + LCU fees
- EBS Volumes: Storage costs for instance root volumes
```
### Cost Optimization

```
- Destroy infrastructure when not in use to avoid unnecessary charges
- Use appropriate instance types for workload requirements
- Monitor AWS Cost Explorer for unexpected charges
- Set up billing alerts in AWS Budgets
```
## Additional Resources

```
- Terraform AWS Provider Documentation
- AWS VPC User Guide
```

```
- Application Load Balancer Documentation
- Amazon EC2 User Guide
- PostgreSQL Official Documentation
```
## Support

For technical issues or clarification:
- Contact your team lead at TechCorp
- Open a ticket in the TechCorp internal support system
- Review Terraform and AWS documentation for common solutions

## Assessment Evidence Requirements

### Required Screenshots

```
- Terraform plan output
- Terraform apply completion
- AWS Console showing all created resources
- Load balancer serving web pages from both instances
- SSH access through bastion host
- SSH access to both web servers
- SSH access to database server
- PostgreSQL connection successful
- Web access via ALB URL visible in screenshot
```
### Submission Files

```
- Complete Terraform configuration files
- User data scripts
- Documentation (README.md)
- All required evidence screenshots
- Terraform state file (ensure no sensitive data)


