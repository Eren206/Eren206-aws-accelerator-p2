variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "macie-lab"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for Macie scan (must be globally unique)"
  type        = string
  default     = "macie-hands-on-demo-v1"
}

variable "email_address" {
  description = "Email address to receive SNS notifications"
  type        = string
  sensitive   = true
  # User must provide this via terraform.tfvars or -var flag
}

variable "macie_job_name" {
  description = "Name for the Macie scanning job"
  type        = string
  default     = "S3-Sensitive-Data-Scan-Job"
}

variable "sns_topic_name" {
  description = "SNS topic name for Macie alerts"
  type        = string
  default     = "Macie-Alerts-Topic"
}

variable "enable_macie_job" {
  description = "Enable Macie job creation (set to false if just testing infrastructure)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
