variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy resource"
}

variable "my_ip" {
  type        = string
  description = "Your public ip address for SSH access to bastion (format x.x.x.x/32) "
}

variable "key_name" {
  type        = string
  default     = "techcorp-key"
  description = "Name of the SSH key pair"
}


variable "bastion_instance_type"{
  type        = string
  default     = "t3.micro"
  description = "Instance type for bastion host"
}


variable "web_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type for web servers"
}

variable "db_instance_type" {
  type        = string
  default     = "t3.small"
  description = "Instance type for database server"
}



