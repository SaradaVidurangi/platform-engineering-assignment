resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.app_name}-cluster"
}

resource "aws_ecs_task_definition" "app" {
  depends_on = [aws_cloudwatch_log_group.ecs_log_group] # 👈 Ensures log group is created first

  family                   = "my-java-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "my-java-app"
    image     = "967823535579.dkr.ecr.us-east-1.amazonaws.com/my-java-app:latest"

    portMappings = [{
      containerPort = 8081
      hostPort      = 8081
    }]

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group         = "/ecs/my-java-app",
        awslogs-region        = "us-east-1",
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}



resource "aws_ecs_service" "app_service" {
  name            = "my-java-app-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

  network_configuration {
    subnets         = [aws_subnet.subnet_a.id]
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "my-java-app"
    container_port   = 8081
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}
