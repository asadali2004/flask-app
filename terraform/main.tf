provider "aws" {
  region = "ap-south-1"
}

######################
# VPC & Networking
######################

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

######################
# Security Group
######################

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

######################
# ECS Cluster
######################

resource "aws_ecs_cluster" "flask_cluster" {
  name = "flask-ecs-cluster"
}

######################
# IAM Role
######################

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

######################
# ECS Task Definition
######################

resource "aws_ecs_task_definition" "flask_task" {
  family                   = "flask-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "flask-container"
    image     = var.docker_image_url
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
  }])
}

######################
# ECS Service
######################

resource "aws_ecs_service" "flask_service" {
  name            = "flask-service"
  cluster         = aws_ecs_cluster.flask_cluster.id
  task_definition = aws_ecs_task_definition.flask_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_attach
  ]
}

######################
# Variables
######################

variable "docker_image_url" {
  description = "Docker image URL from Docker Hub"
  default     = "asadali2004/flask-app:latest"
}
