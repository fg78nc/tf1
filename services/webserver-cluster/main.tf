terraform {
  required_version = ">= 0.12, < 0.13"
  backend "s3" {
    bucket = "terraform-state-bucket-fg78nc-2"
    key = "stage/services/webserver-cluster/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-state-bucket-locks-2"
    encrypt = true
  }
}



data aws_vpc "def" {
  default = true
}

data aws_subnet_ids "default" {
  vpc_id = data.aws_vpc.def.id
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-1"
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}

resource "aws_launch_configuration" "launch_config" {
  image_id = "ami-085925f297f89fce1"
  instance_type = var.instance_type
  security_groups = [aws_security_group.ec2_instance.id]

  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg_group" {
  launch_configuration = aws_launch_configuration.launch_config.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_alb_target_group.alb_target_group.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key = "Name"
    value = "${var.cluster_name}-tf-asg-example"
    propagate_at_launch = true

  }
}

resource "aws_security_group" "ec2_instance" {
  name = "${var.cluster_name}-tf-example-instance"

  ingress {
    from_port = var.server_port
    protocol = local.tcp_protocol
    to_port = var.server_port
    cidr_blocks = local.all_ips
  }
}

resource "aws_lb" "lb_example" {
  name = "${var.cluster_name}-tf-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb_example.arn
  port = 80

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_security_group" "alb_sg" {
  name = "${var.cluster_name}-tf-alb-sg"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.alb_sg.id

  from_port = local.any_port
  to_port = local.any_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = aws_security_group.alb_sg.id

  from_port = local.any_port
  to_port = local.any_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_alb_target_group" "alb_target_group" {
  name = "${var.cluster_name}-terraform-tg"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.def.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority =  100

  condition {
    field = "path-pattern"
    values = ["*"]
  }

  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.alb_target_group.arn
  }

}