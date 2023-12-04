output "web_public_dns" {
  value      = aws_lb.autoscale_group_lb.dns_name
  depends_on = [aws_lb.autoscale_group_lb]
}

