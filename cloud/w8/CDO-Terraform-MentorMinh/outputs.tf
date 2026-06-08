output "web_server_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Gõ IP này vào trình duyệt để test Web Server"
}

output "rds_endpoint" {
  value       = aws_db_instance.mysql.endpoint
  description = "Endpoint để kết nối vào Database"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.assets.id
}