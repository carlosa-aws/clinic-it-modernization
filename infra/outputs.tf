output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "alb_url" {
  value = "http://${aws_lb.app.dns_name}"

}

output "launch_template_id" {
  value = aws_launch_template.app.id
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.app.name
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "rds_port" {
  value = aws_db_instance.postgres.port
}

output "db_name" {
  value = aws_db_instance.postgres.db_name
}

output "db_username" {
  value     = aws_db_instance.postgres.username
  sensitive = true
}

output "app_url" {
  value = "http://${aws_lb.app.dns_name}"
}