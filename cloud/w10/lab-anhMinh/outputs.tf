output "s3_bucket_name" {
  description = "Name of the S3 bucket to be scanned by Macie"
  value       = aws_s3_bucket.macie_scan_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.macie_scan_bucket.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for Macie alerts"
  value       = aws_sns_topic.macie_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.macie_alerts.name
}

output "email_subscription_arn" {
  description = "ARN of the email subscription (you must confirm in email)"
  value       = aws_sns_topic_subscription.macie_alerts_email.arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.macie_findings.name
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.macie_findings.arn
}

output "macie_job_id" {
  description = "ID of the Macie classification job"
  value       = try(aws_macie2_classification_job.s3_scan[0].id, null)
}

output "macie_account_enabled" {
  description = "Whether Macie is enabled in this account"
  value       = var.enable_macie_job ? "Macie is enabled" : "Macie is disabled"
}

output "sample_data_file_location" {
  description = "S3 location of the sample data file"
  value       = "s3://${aws_s3_bucket.macie_scan_bucket.id}/${aws_s3_object.sample_data.key}"
}

output "next_steps" {
  description = "Important next steps"
  value = {
    confirm_email = "Check your email for AWS SNS subscription confirmation and click the confirmation link"
    run_macie_job = var.enable_macie_job ? "Macie job will start automatically or can be started from AWS console" : "Macie job is disabled. Set enable_macie_job=true to enable"
    check_findings = "Once the job completes, check AWS Macie console for findings"
  }
}
