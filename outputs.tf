output "web_public_ip" {
  value      = aws_eip.web_eip[0].public_ip
  depends_on = [aws_eip.web_eip]
}

output "web_public_dns" {
  value      = aws_eip.web_eip[0].public_dns
  depends_on = [aws_eip.web_eip]
}

output "database_endpoint" {
  value = aws_db_instance.database.address
}

output "database_port" {
  value = aws_db_instance.database.port
}

