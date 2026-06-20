# SNS Topic for Macie alerts
resource "aws_sns_topic" "macie_alerts" {
  name              = var.sns_topic_name
  display_name      = "Amazon Macie Sensitive Data Alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-sns-topic"
    }
  )
}

# SNS Topic Policy to allow EventBridge to publish messages
resource "aws_sns_topic_policy" "macie_alerts" {
  arn = aws_sns_topic.macie_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.macie_alerts.arn
      }
    ]
  })
}

# Email subscription to SNS topic
# Note: This creates an unconfirmed subscription
# The user must confirm the subscription via email link
resource "aws_sns_topic_subscription" "macie_alerts_email" {
  topic_arn = aws_sns_topic.macie_alerts.arn
  protocol  = "email"
  endpoint  = var.email_address

  # Prevent Terraform from trying to enable auto_confirms
  # AWS sends a confirmation email that the user must click
}
