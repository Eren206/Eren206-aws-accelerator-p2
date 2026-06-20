# Enable Amazon Macie in the AWS account
resource "aws_macie2_account" "main" {
  count = var.enable_macie_job ? 1 : 0
}

# Wait for Macie to be fully enabled
resource "time_sleep" "wait_for_macie" {
  count           = var.enable_macie_job ? 1 : 0
  create_duration = "10s"

  depends_on = [aws_macie2_account.main]
}

# Macie classification job to scan S3 bucket
resource "aws_macie2_classification_job" "s3_scan" {
  count          = var.enable_macie_job ? 1 : 0
  job_type       = "ONE_TIME"
  name           = var.macie_job_name
  description    = "One-time scan to detect sensitive data in S3 bucket"
  sampling_percentage = 100

  # Configure the S3 bucket to scan
  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = [aws_s3_bucket.macie_scan_bucket.id]
    }
  }

  depends_on = [time_sleep.wait_for_macie]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-classification-job"
    }
  )
}
