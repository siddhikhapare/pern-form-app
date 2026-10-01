output "db_endpoint" {
  description = "RDS PostgreSQL connection endpoint (host:port)"
  value       = aws_db_instance.postgresql.address
}

output "db_instance_id" {
  value = aws_db_instance.postgresql.id
}