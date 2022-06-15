# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available_zones" {
  state = "available"
}

resource "aws_vpc" "docker_vpc" {
  cidr_block = "10.32.0.0/16"
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
  destination_cidr_block = "0.0.0.0/0"
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
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.docker_gateway.*.id, count.index)
  }
}

resource "aws_route_table_association" "docker_private" {
  count          = 2
  subnet_id      = element(aws_subnet.docker_private.*.id, count.index)
  route_table_id = element(aws_route_table.docker_private.*.id, count.index)
}

resource "aws_security_group" "docker_lb_sg" {
  name        = "docker-alb-security-group"
  vpc_id      = aws_vpc.docker_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "docker_lb" {
  name            = "docker-alb"
  subnets         = aws_subnet.docker_public.*.id
  security_groups = [aws_security_group.docker_lb_sg.id]
}

resource "aws_lb_target_group" "hello_world" {
  name        = "docker-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.docker_vpc.id
  target_type = "ip"
}

resource "aws_lb_listener" "hello_world" {
  load_balancer_arn = aws_lb.docker_lb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.hello_world.id
    type             = "forward"
  }
}

resource "aws_ecs_task_definition" "hello_world" {
  family                   = "simple-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  container_definitions = <<DEFINITION
[
  {
    "image": "718206584555.dkr.ecr.us-east-1.amazonaws.com/hello-repository:latest",
    "cpu": 1024,
    "memory": 2048,
    "name": "simple-app",
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
}

resource "aws_security_group" "hello_world_task" {
  name        = "docker-task-security-group"
  vpc_id      = aws_vpc.docker_vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.docker_lb_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "docker_cluster" {
  name = "docker-cluster"
}

resource "aws_ecs_service" "hello_world" {
  name            = "simple-app"
  cluster         = aws_ecs_cluster.docker_cluster.id
  task_definition = aws_ecs_task_definition.hello_world.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.hello_world_task.id]
    subnets         = aws_subnet.docker_private.*.id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.hello_world.id
    container_name   = "simple-app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.hello_world]
}