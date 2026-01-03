# ========================
# General Configuration
# ========================
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "app" {
  description = "Application name for resource tagging"
  type        = string
  default     = "neo"
}

variable "env" {
  description = "Environment (dev only)"
  type        = string
  default     = "dev"
}

variable "author" {
  description = "Author name"
  type        = string
  default     = "Zeb"
}

# ========================
# Security Groups
# ========================
variable "alb_sg_name" {
  description = "Name of ALB security group"
  type        = string
  default     = "neo-eus1-dev-alb-sg"
}

variable "ecs_sg_name" {
  description = "Name of ECS service security group"
  type        = string
  default     = "neo-eus1-dev-ecs-sg"
}

variable "rds_sg_name" {
  description = "Name of RDS security group"
  type        = string
  default     = "neo-eus1-dev-rds-sg"
}

# ========================
# ALB
# ========================
variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "neo-eus1-dev-alb"
}

variable "dev_be_alb_tg_name" {
  description = "Target group name for DEV backend"
  type        = string
  default     = "neo-eus1-dev-alb-tg"
}

# ========================
# ECS
# ========================
variable "ecs_cluster_name" {
  description = "Name of ECS cluster"
  type        = string
  default     = "neo-eus1-dev-ecs-cluster"
}

variable "dev_be_ecr_name" {
  description = "ECR repo name for DEV backend"
  type        = string
  default     = "neo-eus1-dev-be-ecr"
}

variable "ecs_task_execution_role_name" {
  description = "Name of ECS task execution IAM role"
  type        = string
  default     = "neo-eus1-dev-taskexecutionrole"
}

variable "dev_be_ecs_task_family" {
  description = "ECS task family for DEV backend"
  type        = string
  default     = "neo-eus1-dev-be-ecs-task-family"
}

variable "container_name" {
  description = "Container name for DEV backend"
  type        = string
  default     = "neo-eus1-dev-be-container"
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "ecs_service_name_dev_be" {
  type    = string
  default = "neo-eus1-dev-be-ecs-service"
}

# ========================
# S3 & CloudFront
# ========================
variable "bucket_name_dev" {
  description = "S3 bucket for frontend hosting"
  type        = string
  default     = "neo-eus1-dev-frontend-bucket"
}

# ========================
# RDS
# ========================
variable "rds_subnet_group_name" {
  description = "Name of RDS subnet group"
  type        = string
  default     = "neo-eus1-dev-rds-subgrp"
}

variable "rds_identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "neo-eus1-dev-rds-postgresqldb"
}

variable "rds_engine" {
  type    = string
  default = "postgres"
}

variable "rds_engine_version" {
  type    = string
  default = "17.5"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  type    = number
  default = 10
}

variable "rds_backup_retention_period" {
  type    = number
  default = 7
}

# ========================
# Secrets Manager
# ========================
variable "dev_secret_name" {
  type    = string
  default = "neo-eus1-dev-credentials"
}
