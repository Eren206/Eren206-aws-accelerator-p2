# 1. Tạo IAM Role (Chỉ cần quyền đẩy log/metric về CloudWatch)
resource "aws_iam_role" "ec2_cw_only_role" {
  name = "ec2-cloudwatch-agent-only-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

# CHỈ gán duy nhất policy của CloudWatch
resource "aws_iam_role_policy_attachment" "cw_agent_only" {
  role       = aws_iam_role.ec2_cw_only_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-cw-only-instance-profile"
  role = aws_iam_role.ec2_cw_only_role.name
}

# 2. Khởi tạo EC2 và cấu hình Agent cục bộ qua User Data
resource "aws_instance" "web_server" {
  ami                  = "ami-0c7217cdde317cfec" # Thay bằng AMI phù hợp của bạn (Ví dụ: Amazon Linux 2023)
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Toàn bộ quá trình cài đặt và cấu hình gói gọn trong này
  user_data = <<-EOF
              #!/bin/bash
              # Bước 1: Cài đặt CloudWatch Agent từ S3 của AWS (Ví dụ cho RHEL/Amazon Linux)
              sudo rpm -Uvh https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
              
              # Bước 2: Tạo thư mục cấu hình nếu chưa có
              sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/
              
              # Bước 3: Ghi trực tiếp file cấu hình JSON vào local disk của EC2
              sudo cat << 'INNER_EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
              {
                "agent": {
                  "metrics_collection_interval": 60,
                  "run_as_user": "cwagent"
                },
                "metrics": {
                  "metrics_collected": {
                    "disk": {
                      "measurement": ["disk_used_percent"],
                      "metrics_collection_interval": 60,
                      "resources": ["*"]
                    },
                    "mem": {
                      "measurement": ["mem_used_percent"],
                      "metrics_collection_interval": 60
                    }
                  }
                }
              }
              INNER_EOF

              # Bước 4: Khởi động Agent và chỉ định đọc file cấu hình cục bộ vừa tạo
              sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config \
                -m ec2 \
                -s \
                -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
              EOF

  tags = {
    Name = "EC2-Direct-CloudWatch-Agent"
  }
}