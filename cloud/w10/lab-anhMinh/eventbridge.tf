# EventBridge Rule to capture Macie findings and send to SNS
resource "aws_cloudwatch_event_rule" "macie_findings" {
  name        = "Macie-To-SNS-Alert-Rule"
  description = "Capture Amazon Macie findings and forward to SNS"

  # Event pattern to match Macie findings
  event_pattern = jsonencode({
    source      = ["aws.macie"]
    detail-type = ["Macie Finding"]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eventbridge-rule"
    }
  )
}

# EventBridge Target - SNS Topic
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.macie_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.macie_alerts.arn

  # Format the event as plain text for better readability in email
  input_transformer {
    input_paths = {
      source      = "$.source"
      account     = "$.account"
      region      = "$.region"
      time        = "$.time"
      severity    = "$.detail.severity"
      finding_arn = "$.detail.findingArn"
      type        = "$.detail.type"
      resources   = "$.detail.resources"
      title       = "$.detail.title"
    }
    input_template = "\"AWS Macie Finding Alert\\n\\nTitle: <title>\\nSeverity: <severity>\\nType: <type>\\nTime: <time>\\nAccount: <account>\\nRegion: <region>\\nFinding ARN: <finding_arn>\\n\\nResources:\\n<resources>\""
  }

  depends_on = [aws_sns_topic_policy.macie_alerts]
}
