# AWS Macie Hands-On Lab - Terraform Implementation

This Terraform configuration implements the complete AWS Macie lab for detecting sensitive data in Amazon S3 buckets and sending notifications via Amazon SNS.

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                    AWS Cloud                                   │
├──────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐                                               │
│  │  S3 Bucket  │──────┐                                        │
│  │ (with PII)  │      │                                        │
│  └─────────────┘      │                                        │
│                       │                                        │
│                       ▼                                        │
│              ┌──────────────────┐                              │
│              │ Amazon Macie Job │                              │
│              │  (One-Time Scan) │                              │
│              └──────────────────┘                              │
│                       │                                        │
│                       ▼ (Findings)                            │
│              ┌──────────────────┐                              │
│              │  EventBridge     │                              │
│              │    Rule          │                              │
│              └──────────────────┘                              │
│                       │                                        │
│                       ▼                                        │
│              ┌──────────────────┐                              │
│              │   SNS Topic      │──────→ Email to User       │
│              │  (Macie Alerts)  │                              │
│              └──────────────────┘                              │
│                                                                 │
└──────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **AWS Account**: An active AWS account with appropriate permissions
2. **Terraform**: Version 1.0 or higher installed
3. **AWS CLI**: Configured with appropriate credentials (optional but recommended)
4. **Email Address**: A valid email address to receive SNS notifications

## Setup Instructions

### Step 1: Prepare Configuration Variables

1. Copy `terraform.tfvars.example` to `terraform.tfvars`:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` and update the required variables:
   - Replace `your-email@example.com` with your actual email address
   - Update `aws_region` if needed (default: ap-southeast-1)
   - Other variables can remain as defaults

```hcl
email_address = "your-actual-email@example.com"
aws_region    = "ap-southeast-1"
```

### Step 2: Initialize Terraform

Initialize the Terraform working directory:

```bash
cd "Detect Sensitive data in Amazon S3 buckets and sent notifications using Amazon Macie"
terraform init
```

### Step 3: Review the Plan

Before applying, review what resources will be created:

```bash
terraform plan -out=tfplan
```

This will show:
- 1 S3 Bucket with encryption and public access blocking
- 1 SNS Topic for alerts
- 1 Email subscription to SNS
- 1 Macie classification job
- 1 EventBridge rule to forward Macie findings to SNS
- Sample data file with sensitive information

### Step 4: Apply Configuration

Apply the Terraform configuration to create resources:

```bash
terraform apply tfplan
```

**Important**: After applying, you will receive an email from AWS SNS asking to confirm your subscription. You MUST click the confirmation link in that email for alerts to work.

### Step 5: Confirm SNS Subscription

1. Check your email inbox (including spam folder)
2. Look for email with subject: "AWS Notification - Subscription Confirmation"
3. Click the confirmation link in the email
4. You should see "Subscription confirmed!" message

### Step 6: Monitor Macie Job Execution

1. Log into AWS Management Console
2. Go to Amazon Macie service
3. Navigate to Jobs section
4. Your job "S3-Sensitive-Data-Scan-Job" should appear
5. Check the status (typically takes 5-30 minutes depending on file size)

### Step 7: Review Findings

Once the Macie job completes:

1. Go to Amazon Macie → Findings section
2. You should see findings related to detected sensitive data:
   - Credit card numbers (format: Personal/CreditCardNumber)
   - Personal identifiable information (PII)
   - Credentials/API Keys
   - Email addresses
   - Phone numbers
   - ID numbers

3. Check your email for SNS notifications with finding details

## Files Overview

| File | Purpose |
|------|---------|
| `providers.tf` | AWS provider configuration |
| `variables.tf` | Input variables for customization |
| `s3.tf` | S3 bucket setup with encryption and sample data upload |
| `sns.tf` | SNS topic and email subscription |
| `macie.tf` | Macie account enablement and classification job |
| `eventbridge.tf` | EventBridge rule to forward findings to SNS |
| `outputs.tf` | Output values with important information |
| `sample_data.txt` | Sample file with simulated sensitive data for testing |
| `terraform.tfvars.example` | Example variables file (copy to terraform.tfvars) |
| `terraform.tfstate` | Terraform state file (automatically created) |
| `README.md` | This file |

## Important Notes

### Email Confirmation Required
- The SNS subscription will NOT work until you confirm via the confirmation email
- Check spam folder if you don't see the email within a few minutes
- If the email doesn't arrive, you can manually confirm from AWS Console:
  - Go to SNS → Topics → Macie-Alerts-Topic → Subscriptions
  - Find your email subscription with status "PendingConfirmation"
  - Click "Confirm subscription" button

### Sensitive Data in Sample File
The `sample_data.txt` file contains realistic but FICTIONAL sensitive data:
- Fake credit card numbers (4111 1111 1111 1111 is a test number)
- Fake ID numbers
- Fake API keys and credentials

**WARNING**: Do NOT use real sensitive data in this lab.

### Macie Job Duration
- The Macie classification job may take 5-30 minutes to complete
- Duration depends on file size and AWS service queue
- You can monitor progress in AWS Console

### Cost Considerations
- Macie charges per 1000 objects scanned (typically very low for small labs)
- S3 storage costs are minimal for small files
- SNS notifications are free for 1000 emails per month
- Total estimated cost for this lab: < $1 USD

## Cleanup and Destruction

To remove all resources and avoid ongoing charges:

```bash
# Before destroying, you might want to save any logs
terraform destroy
```

You will be prompted to confirm. Type `yes` to proceed.

This will delete:
- ✓ S3 bucket and all objects
- ✓ SNS topic and subscriptions
- ✓ EventBridge rule
- ✓ Macie classification job
- ✓ Macie account (if you set enable_macie_job = false in the last run)

**Manual Cleanup Note**: If Macie account remains enabled in AWS console, you may need to manually disable it from AWS Macie settings to avoid charges.

## Troubleshooting

### Issue: Email subscription confirmation not received
**Solution**: 
1. Check spam/junk folder
2. Check the email address in `terraform.tfvars`
3. Manually confirm from AWS Console (SNS → Subscriptions)

### Issue: Macie job shows no findings
**Possible causes**:
1. Job is still running (wait a few minutes)
2. Macie may not have detected the sensitive data patterns
3. Check Macie job status in AWS Console
4. Verify S3 bucket name matches what was created

### Issue: SNS notifications not arriving
**Possible causes**:
1. Email subscription not confirmed
2. Macie job hasn't completed yet
3. EventBridge rule not properly connected to SNS
4. Check AWS CloudWatch Logs for EventBridge rule errors

### Issue: Terraform apply fails
**Possible solutions**:
1. Verify AWS credentials are correctly configured
2. Ensure your AWS account has Macie permissions
3. Check that `email_address` variable is set
4. Try running `terraform init` again

## Outputs

After successful `terraform apply`, you'll see output values including:
- S3 bucket name
- SNS topic ARN
- EventBridge rule name
- Macie job ID
- Sample data file location
- Important next steps

You can view outputs anytime with:

```bash
terraform output
```

## Additional Resources

- [AWS Macie Documentation](https://docs.aws.amazon.com/macie/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS SNS Documentation](https://docs.aws.amazon.com/sns/)
- [AWS EventBridge Documentation](https://docs.aws.amazon.com/eventbridge/)

## Lab Completion Checklist

- [ ] Terraform files copied and variables configured
- [ ] `terraform init` completed successfully
- [ ] `terraform plan` reviewed
- [ ] `terraform apply` completed
- [ ] Email subscription confirmation received and clicked
- [ ] Macie job completed (check AWS Console)
- [ ] Findings appear in Macie console
- [ ] Email notification received with finding details
- [ ] Resources cleaned up with `terraform destroy`

## Support

For issues or questions:
1. Check AWS Console for service status
2. Review Terraform logs: `TF_LOG=DEBUG terraform apply`
3. Check AWS CloudWatch Logs for EventBridge execution errors
4. Verify IAM permissions for Macie operations

---

**Last Updated**: 2026-06-19
**Lab Duration**: 30-45 minutes
**AWS Services Used**: S3, SNS, Macie, EventBridge, IAM
