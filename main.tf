# configure aws provider
provider "aws" {
  region = var.region
}

# get default vpc
data "aws_vpc" "default" {
  default = true
}

# get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# security group for alb
resource "aws_security_group" "alb_sg" {
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for Application Load Balancer"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
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
    Name   = var.alb_sg_name
    app    = var.app
    env    = var.env
    author = var.author
  }
}

# security group for rds
resource "aws_security_group" "rds_sg" {
  name        = var.rds_sg_name
  description = "security group for rds"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = var.rds_sg_name
    app    = var.app
    env    = var.env
    author = var.author
  }
}

# security group for ecs
resource "aws_security_group" "ecs_sg" {
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for ECS service"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = var.ecs_sg_name
    app    = var.app
    env    = var.env
    author = var.author
  }
}
# Application Load Balancer
resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
  tags = {
    Name   = var.alb_name
    app    = var.app
    env    = var.env
    author = var.author
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "dev_be_alb_tg" {
  name        = var.dev_be_alb_tg_name
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
  health_check {
    path                = "/api/document/healthCheck"
    healthy_threshold   = 2
    interval            = 10
    unhealthy_threshold = 10
  }
  tags = {
    Name   = var.dev_be_alb_tg_name
    app    = var.app
    env    = var.env
    author = var.author
  }
}

# HTTP Listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 8080
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_be_alb_tg.arn
  }
  tags = {
    Name   = "neo-eus1-http-listener"
    app    = var.app
    env    = var.env
    author = var.author
  }
}


# Backend ECR repository
resource "aws_ecr_repository" "dev_be_ecr" {
  name = var.dev_be_ecr_name
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name   = var.dev_be_ecr_name
    app    = var.app
    env    = var.env
    author = var.author
  }
}




# ecs cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Name   = var.ecs_cluster_name
    app    = var.app
    env    = var.env
    author = var.author
  }
}

# task execution role for ecs task definition
resource "aws_iam_role" "ecs_task_execution_role" {
  name = var.ecs_task_execution_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name   = var.ecs_task_execution_role_name
    app    = var.app
    env    = var.env
    author = var.author
  }
}

# attach amazonecstaskexecutionrolepolicy to the ecs task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# attach secretsmanager read policy to the ecs task execution role
resource "aws_iam_role_policy_attachment" "ecs_secretsmanager_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

#attach cloudwatch logs policy to the ecs task execution role
resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
# ECS Task Definition - dev
resource "aws_ecs_task_definition" "task_definition_dev_be" {
  family                   = var.dev_be_ecs_task_family
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  network_mode             = "awsvpc"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      cpu       = 1024
      memory    = 2048
      essential = true
      image     = "${aws_ecr_repository.dev_be_ecr.repository_url}:latest"
      environment = [
        {
          name  = "SECRET_STORE_NAME"
          value = var.dev_secret_name
        },
        {
          name  = "AWS_REGION"
          value = var.region
        }
      ]
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-create-group"  = "true"
          "awslogs-group"         = "${aws_cloudwatch_log_group.dev_be_ecs_logs.name}"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      secrets = []
    }
  ])

  tags = {
    Name   = var.dev_be_ecs_task_family
    app    = var.app
    env    = var.env
    author = var.author
  }
}

# CloudWatch Log Group for dev ECS Task
resource "aws_cloudwatch_log_group" "dev_be_ecs_logs" {
  name              = "/ecs/${var.dev_be_ecs_task_family}"
  retention_in_days = 7
}


# ECS Service - dev_be
resource "aws_ecs_service" "ecs_service_dev_be" {
  name            = var.ecs_service_name_dev_be
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition_dev_be.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dev_be_alb_tg.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  tags = {
    Name   = var.ecs_service_name_dev_be
    app    = var.app
    env    = var.env
    author = var.author
  }

  depends_on = [
    aws_lb_listener.http_listener
  ]
}



# Create the S3 bucket for frontend
resource "aws_s3_bucket" "frontend_dev" {
  bucket        = var.bucket_name_dev
  force_destroy = true

  tags = {
    Name   = var.bucket_name_dev
    env    = var.env
    app    = var.app
    author = var.author
  }
}

resource "aws_s3_bucket_versioning" "frontend_dev_versioning" {
  bucket = aws_s3_bucket.frontend_dev.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_dev_block" {
  bucket                  = aws_s3_bucket.frontend_dev.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "oac_dev" {
  name                              = "neo-eus1-cf-oac-s3-fe-dev"
  description                       = "OAC for DEV frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "frontend_dev" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront for S3-hosted frontend - neo DEV"
  default_root_object = "index.html"
 
  origin {
    domain_name              = aws_s3_bucket.frontend_dev.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.frontend_dev.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac_dev.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.frontend_dev.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Managed-CachingOptimized
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    # Managed-AllViewer (includes cookies, headers, query strings)
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"

    # Dev-friendly short cache
    min_ttl     = 0
    default_ttl = 60
    max_ttl     = 300
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name   = "neo-eus1-cf-oac-s3-fe-dev"
    app    = var.app
    env    = var.env
    author = var.author
  }
}

resource "aws_s3_bucket_policy" "frontend_dev_policy" {
  bucket = aws_s3_bucket.frontend_dev.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend_dev.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.frontend_dev.arn
        }
      }
    }]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.frontend_dev_block
  ]
}

# RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = var.rds_subnet_group_name
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name   = var.rds_subnet_group_name
    app    = var.app
    env    = var.env
    author = var.author
  }
}

# RDS Instance
resource "aws_db_instance" "rds_db" {
  identifier                = var.rds_identifier
  engine                    = var.rds_engine
  instance_class            = var.rds_instance_class
  allocated_storage         = var.rds_allocated_storage
  storage_type              = "gp2"
  engine_version            = var.rds_engine_version
  db_name                   = "neotrainer"
  username                  = "postgres"
  password                  = "password123"
  publicly_accessible       = false
  multi_az                  = false
  backup_retention_period   = var.rds_backup_retention_period
  storage_encrypted         = true
  skip_final_snapshot       = true
  deletion_protection       = false
  vpc_security_group_ids    = [aws_security_group.rds_sg.id]
  db_subnet_group_name      = aws_db_subnet_group.rds_subnet_group.name
  
  tags = {
    Name   = var.rds_identifier
    app    = var.app
    env    = var.env
    author = var.author
  }
}

# AWS Secret Manager
resource "aws_secretsmanager_secret" "dev_secret" {
  name = var.dev_secret_name

  tags = {
    Name   = var.dev_secret_name
    app    = var.app
    env    = var.env
    author = var.author
  }
}
