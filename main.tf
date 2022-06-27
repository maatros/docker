# Configure the AWS provider
provider "aws" {
  region = var.region
}

# Remote state configured with S3 bucket
terraform {
  backend "s3" {
    bucket         = "docker-project-bucket"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "docker-project-locks"
    encrypt        = true
  }
}

data "aws_availability_zones" "available_zones" {
  state = var.availability_zones_state
}

resource "aws_vpc" "docker_vpc" {
  cidr_block = var.docker_private_subnet_CIDR
}

resource "aws_subnet" "docker_public" {
  count                   = 2
  cidr_block              = cidrsubnet(aws_vpc.docker_vpc.cidr_block, 8, 2 + count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id                  = aws_vpc.docker_vpc.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "docker_private" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.docker_vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id            = aws_vpc.docker_vpc.id
}

resource "aws_internet_gateway" "docker_internet_gateway" {
  vpc_id = aws_vpc.docker_vpc.id
}

resource "aws_route" "docker_internet_access" {
  route_table_id         = aws_vpc.docker_vpc.main_route_table_id
  destination_cidr_block = var.route_destination
  gateway_id             = aws_internet_gateway.docker_internet_gateway.id
}

resource "aws_eip" "docker_gateway" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.docker_internet_gateway]
}

resource "aws_nat_gateway" "docker_gateway" {
  count         = 2
  subnet_id     = element(aws_subnet.docker_public.*.id, count.index)
  allocation_id = element(aws_eip.docker_gateway.*.id, count.index)
}

resource "aws_route_table" "docker_private" {
  count  = 2
  vpc_id = aws_vpc.docker_vpc.id

  route {
    cidr_block = var.route_destination
    nat_gateway_id = element(aws_nat_gateway.docker_gateway.*.id, count.index)
  }
}

resource "aws_route_table_association" "docker_private" {
  count          = 2
  subnet_id      = element(aws_subnet.docker_private.*.id, count.index)
  route_table_id = element(aws_route_table.docker_private.*.id, count.index)
}

resource "aws_security_group" "docker_lb_sg" {
  name        = var.docker_application_load_balancer_security_group_name
  vpc_id      = aws_vpc.docker_vpc.id

  ingress {
    protocol    = var.docker_application_load_balancer_security_group_ingress_protocols
    from_port   = var.docker_application_load_balancer_security_group_ingress_ports
    to_port     = var.docker_application_load_balancer_security_group_ingress_ports
    cidr_blocks = [var.docker_application_load_balancer_security_group_ingress_CIDR_blocks]
  }

  egress {
    from_port = var.docker_application_load_balancer_security_group_egress_ports
    to_port   = var.docker_application_load_balancer_security_group_egress_ports
    protocol  = var.docker_application_load_balancer_security_group_egress_protocols
    cidr_blocks = [var.docker_application_load_balancer_security_group_egress_CIDR_blocks]
  }
}

resource "aws_lb" "docker_lb" {
  name            = var.docker_application_load_balancer_name
  subnets         = aws_subnet.docker_public.*.id
  security_groups = [aws_security_group.docker_lb_sg.id]
}

resource "aws_lb_target_group" "hello_world" {
  name        = var.docker_application_load_balancer_target_group_name
  port        = var.docker_application_load_balancer_target_group_port
  protocol    = var.docker_application_load_balancer_target_group_protocol
  vpc_id      = aws_vpc.docker_vpc.id
  target_type = var.docker_application_load_balancer_target_group_target_type
}

resource "aws_lb_listener" "hello_world" {
  load_balancer_arn = aws_lb.docker_lb.id
  port              = var.docker_application_load_balancer_listener_port
  protocol          = var.docker_application_load_balancer_listener_protocol

  default_action {
    target_group_arn = aws_lb_target_group.hello_world.id
    type             = var.docker_application_load_balancer_listener_default_action_type
  }
}
resource "time_sleep" "wait_for_new_version_of_docker_image" {
  create_duration = "60s"
}

# ----- This section is only for workaround purpose BEGIN -----
data "aws_ecr_image" "aws_ecr_docker_image" {
  repository_name = "718206584555.dkr.ecr.us-east-1.amazonaws.com/from-git-repository"
  image_tag       = "latest"
}
# ----- This section is only for workaround purpose END -----
resource "aws_ecs_task_definition" "hello_world" {
  family                   = var.docker_ecs_task_definition_family
  network_mode             = var.docker_ecs_task_definition_network_mode
  requires_compatibilities = [var.docker_ecs_task_definition_requires_compatibilities]
  cpu                      = var.docker_ecs_task_definition_cpu
  memory                   = var.docker_ecs_task_definition_memory
  execution_role_arn       = var.task_execution_role
  container_definitions = <<DEFINITION
[
  {
    "image": "${data.aws_ecr_docker_image.repository_name}:${data.aws_ecr_docker_image.image_tag}@${data.aws_ecr_image.aws_ecr_docker_image.image_digest}",
    "cpu": 1024,
    "memory": 2048,
    "essential" : true,
    "name": "simple-container",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
DEFINITION
  depends_on =  [time_sleep.wait_for_new_version_of_docker_image]
}

resource "aws_security_group" "hello_world_task" {
  name        = var.docker_task_security_group_name
  vpc_id      = aws_vpc.docker_vpc.id

  ingress {
    protocol        = var.docker_task_security_group_ingresss_protocol
    from_port       = var.docker_task_security_group_ingres_port
    to_port         = var.docker_task_security_group_ingres_port
    security_groups = [aws_security_group.docker_lb_sg.id]
  }

  egress {
    protocol    = var.docker_task_security_group_egress_protocol
    from_port   = var.docker_task_security_group_egress_port
    to_port     = var.docker_task_security_group_egress_port
    cidr_blocks = [var.docker_task_security_group_egress_CIDR_blocks]
  }
}

resource "aws_ecs_cluster" "docker_cluster" {
  name = var.docker_ecs_cluster_name
}

resource "aws_ecs_service" "hello_world_service" {
  name            = var.docker_ecs_service_name
  cluster         = aws_ecs_cluster.docker_cluster.id
  task_definition = aws_ecs_task_definition.hello_world.arn
  desired_count   = var.app_count
  launch_type     = var.docker_ecs_service_launch_type
  force_new_deployment = var.docker_ecs_service_force_new_deployment
  network_configuration {
    security_groups = [aws_security_group.hello_world_task.id]
    subnets         = aws_subnet.docker_private.*.id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.hello_world.id
    container_name   = var.docker_ecs_service_container_name
    container_port   = var.docker_ecs_service_container_port
  }
  depends_on = [aws_lb_listener.hello_world]
}


