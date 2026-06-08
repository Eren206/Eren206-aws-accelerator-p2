# backend-setup/main.tf
provider "aws" { region = "us-east-1" }

# S3 Bucket để lưu file terraform.tfstate
resource "aws_s3_bucket" "tf_state" {
  bucket        = "cdo-g7-tydinhvan2062002-unique" 
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration { status = "Enabled" } # Bật versioning để khôi phục state cũ nếu lỗi
}

# DynamoDB để quản lý cơ chế State Locking (Chặn nhiều người apply cùng lúc)
resource "aws_dynamodb_table" "tf_locks" {
  name         = "cdo-g7-terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}