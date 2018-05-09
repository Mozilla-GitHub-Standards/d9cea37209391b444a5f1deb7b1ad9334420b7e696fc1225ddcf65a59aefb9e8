# Create ECS cluster service

resource "aws_ecs_service" "ecs-service" {
  name            = "${var.service_name}"
  cluster         = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.task-definition.arn}"
  desired_count   = 1

  network_configuration {
    subnets         = ["${var.ecs_subnets}"]
    security_groups = ["${var.awsvpc_sg}"]
  }
}

# Create a new task definition

resource "aws_ecs_task_definition" "task-definition" {
  family = "${var.service_name}"

  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]

  container_definitions = <<DEFINITION
[
  {
    "cpu": 128,
    "essential": true,
    "image": "httpd:latest",
    "memory": 128,
    "memoryReservation": 64,
    "name": "redirects",
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

# ECR configuration

resource "aws_ecr_repository" "ecr-repository" {
  name = "${var.service_name}"
}

# resource "aws_lb" "ecs-redirects-alb" {
#   name            = "ecs-lb-tf"
#   internal        = false
#   security_groups = ["${aws_security_group.redirects_lb_sg.id}"]
#   subnets         = ["${aws_subnet.ecs-subnet1.id}", "${aws_subnet.ecs-subnet2.id}"]


#   enable_deletion_protection = false
# }

