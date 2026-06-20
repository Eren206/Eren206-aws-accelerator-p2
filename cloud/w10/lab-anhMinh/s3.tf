# S3 Bucket for Macie to scan
resource "aws_s3_bucket" "macie_scan_bucket" {
  bucket = "${var.s3_bucket_name}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-bucket"
    }
  )
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "macie_scan_bucket" {
  bucket = aws_s3_bucket.macie_scan_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for backup purposes
resource "aws_s3_bucket_versioning" "macie_scan_bucket" {
  bucket = aws_s3_bucket.macie_scan_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "macie_scan_bucket" {
  bucket = aws_s3_bucket.macie_scan_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload sample data file to S3
resource "aws_s3_object" "sample_data" {
  bucket = aws_s3_bucket.macie_scan_bucket.id
  key    = "sample_data.txt"
  source = "${path.module}/sample_data.txt"

  # Trigger updates when file changes
  etag = filemd5("${path.module}/sample_data.txt")

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-sample-data"
    }
  )

  depends_on = [
    aws_s3_bucket_public_access_block.macie_scan_bucket
  ]
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}
