output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.tg.arn
}

output "alb_sg_id" {
  value = aws_lb.alb.security_groups[0]
}
