# ═══════════════════════════════════════════════════════════════
# ShopFlow — Outputs
# ═══════════════════════════════════════════════════════════════

output "ec2_public_ip" {
  description = "EC2 public IP address"
  value       = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  description = "EC2 public DNS"
  value       = aws_instance.app.public_dns
}

output "app_url" {
  description = "ShopFlow application URL"
  value       = "http://${aws_instance.app.public_ip}/"
}

output "log_viewer_url" {
  description = "Dozzle log viewer URL"
  value       = "http://${aws_instance.app.public_ip}:8080"
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.app.public_ip}"
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.mysql.port
}

output "bootstrap_log_command" {
  description = "Command to watch bootstrap progress on EC2"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.app.public_ip} 'sudo tail -f /var/log/shopflow-bootstrap.log'"
}
