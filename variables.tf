#Default region
variable "region" {
  type    = string
  default = "us-east-1"
}

#Application count - how many docker instances should start
variable "app_count" {
  type = number
  default = 3
}

#Availability Zones - use all available
variable "availability_zones_state" {
  type = string
  default = "available"
  
}
variable "task_execution_role"{
  type = string
  default = "arn:aws:iam::718206584555:role/ecsTaskExecutionRole"
}
variable "docker_private_subnet_CIDR" {
  default = "10.32.0.0/16"
}
variable "route_destination" {
  type = string
  default = "0.0.0.0/0"
}
# ----- Application Load Balancer Section BEGIN -----
variable "docker_application_load_balancer_security_group_name" {
  type = string
  default = "docker-alb-security-group"
}
variable "docker_application_load_balancer_name" {
  type = string
  default = "docker-alb"
}
# ----- Application Load Balancer Section END -----

# ----- Application Load Balancer Security Group Section BEGIN -----
variable "docker_application_load_balancer_security_group_ingress_protocols" {
  type    = string
  default = "tcp"
}
variable "docker_application_load_balancer_security_group_ingress_ports" {
  type    = number
  default = 80
}
variable "docker_application_load_balancer_security_group_egress_protocols" {
  type    = string
  default = "-1"
}
variable "docker_application_load_balancer_security_group_egress_ports" {
  type    = number
  default = 0
}
variable "docker_application_load_balancer_security_group_ingress_CIDR_blocks" {
  default = "0.0.0.0/0"
}
variable "docker_application_load_balancer_security_group_egress_CIDR_blocks" {
  default = "0.0.0.0/0"
}
# ----- Application Load Balancer Security Group Section END -----

# ----- Application Load Balancer Target Group Section BEGIN -----
variable "docker_application_load_balancer_target_group_name" {
  type = string
  default = "docker-target-group"
}

variable "docker_application_load_balancer_target_group_port" {
  type = number
  default = 80
}

variable "docker_application_load_balancer_target_group_protocol" {
  type = string
  default = "HTTP"
}
variable "docker_application_load_balancer_target_group_target_type" {
  type = string
  default = "ip"
}
# ----- Application Load Balancer Target Group Section END -----

# ----- Application Load Balancer Listener Section BEGIN -----
variable "docker_application_load_balancer_listener_port" {
  type = number
  default = 80
}
variable "docker_application_load_balancer_listener_protocol" {
  type = string
  default = "HTTP"
}
variable "docker_application_load_balancer_listener_default_action_type" {
  type = string
  default = "forward"
}
# ----- Application Load Balancer Listener Section END -----

# ----- Docker Task Security Group Section BEGIN -----

variable "docker_task_security_group_name" {
  type = string
  default = "docker-task-security-group"
}
variable "docker_task_security_group_ingresss_protocol" {
  type = string
  default = "tcp"
}
variable "docker_task_security_group_ingres_port" {
  type = number
  default = 80
}
variable "docker_task_security_group_egress_protocol" {
  type = string
  default = "-1"
}
variable "docker_task_security_group_egress_port" {
  type = number
  default = 0
}
variable "docker_task_security_group_egress_CIDR_blocks" {
  default = "0.0.0.0/0"
}

# ----- Docker Task Security Group Section END -----

# ECS Cluster Name
variable "docker_ecs_cluster_name" {
  type = string
  default = "docker-cluster"
}

# ----- Docker ECS Service Section BEGIN -----

variable "docker_ecs_service_name" {
  type = string
  default = "simple-service"
}
variable "docker_ecs_service_launch_type" {
  type = string
  default = "FARGATE"
}
variable "docker_ecs_service_force_new_deployment" {
  type = bool
  default = true
}
variable "docker_ecs_service_container_name" {
  type = string
  default = "simple-container"
}
variable "docker_ecs_service_container_port" {
  type = number
  default = 80
}


# ----- Docker ECS Service Section END -----

# ----- Docker ECS Task Definition Section BEGIN -----
variable "docker_ecs_task_definition_family" {
  type = string
  default = "simple-container"
}
variable "docker_ecs_task_definition_network_mode" {
  type = string
  default = "awsvpc"
}
variable "docker_ecs_task_definition_requires_compatibilities" {
  type = string
  default = "FARGATE"
}
variable "docker_ecs_task_definition_cpu" {
  type = string
  default = "1024"
}
variable "docker_ecs_task_definition_memory" {
  type = string
  default = "2048"
}
# ----- Docker ECS Task Definition Section END -----