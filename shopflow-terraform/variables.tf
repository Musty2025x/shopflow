# ═══════════════════════════════════════════════════════════════
# ShopFlow — Input Variables
# ═══════════════════════════════════════════════════════════════

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "shopflow"
}

# ── Networking ────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR (EC2)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr_a" {
  description = "Private subnet CIDR AZ-a (RDS)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr_b" {
  description = "Private subnet CIDR AZ-b (RDS — required for subnet group)"
  type        = string
  default     = "10.0.3.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into EC2 — use YOUR_IP/32"
  type        = string
  default     = "0.0.0.0/0"
}

# ── EC2 ──────────────────────────────────────────────────────
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "AWS key pair name (must exist in your account)"
  type        = string
}

# ── RDS ──────────────────────────────────────────────────────
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "MySQL database name"
  type        = string
  default     = "shopflow"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "shopflow_user"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

# ── App ──────────────────────────────────────────────────────
variable "jwt_secret" {
  description = "JWT signing secret — minimum 32 characters"
  type        = string
  sensitive   = true
}

variable "repo_url" {
  description = "GitHub repo URL to clone on EC2"
  type        = string
  default     = "https://github.com/Musty2025x/shopflow.git"
}
