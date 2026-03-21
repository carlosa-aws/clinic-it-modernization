variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "clinic-mvp"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "Second subnet CIDR block for DB subnet group"
  type        = string
  default     = "10.0.2.0/24"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR format for temporary app testing"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "clinicdb"
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "clinicadmin"
}

variable "db_password" {
  description = "Database admin password"
  type        = string
  sensitive   = true
}