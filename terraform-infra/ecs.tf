resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.app_name}-cluster"
}

resource "aws_ecs_task_definition" "app_small" {
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
resource "aws_ecs_task_definition" "app_medium" {
  family                   = "my-java-app"
  cpu                      = "512" # 0.5 vCPU
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = aws_ecs_task_definition.app_small.container_definitions
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "high-cpu-ecs"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Trigger when CPU > 70%"
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.app_service.name
  }
  alarm_actions = [aws_sns_topic.vertical_scaling_topic.arn]
}
