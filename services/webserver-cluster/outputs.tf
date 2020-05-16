output "alb_dns_name" {
  value = aws_lb.lb_example.dns_name
  description = "The domain name of the load balancer"
}

output "aws_autoscaling_group_name" {
  value = aws_autoscaling_group.asg_group.name
  description = "The anme of the auto scaling group"
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
  description = "The ID of the Security Group attached to the load balancer"
}