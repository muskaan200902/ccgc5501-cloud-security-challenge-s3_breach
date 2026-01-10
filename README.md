# Cloud Breach S3 - Terraform Scenario

A customizable "vulnerable by design" AWS environment inspired by the Capital One breach and CloudGoat's `cloud_breach_s3` scenario.

## 🎯 Scenario Overview

**Goal:** Download confidential files from an S3 bucket

**Starting Point:** You are given the IP address of an EC2 instance running a misconfigured reverse proxy

**Attack Path:**
1. Exploit misconfigured reverse proxy
2. Query EC2 Instance Metadata Service (IMDS)
3. Steal IAM credentials
4. Access and exfiltrate S3 data

## 📦 Resources Created

| Resource | Description |
|----------|-------------|
| VPC | Isolated network environment |
| EC2 Instance | Vulnerable reverse proxy (nginx) |
| S3 Bucket | Contains "sensitive" cardholder data |
| IAM Role | Attached to EC2 with S3 read access |
| Security Group | Allows HTTP (and optionally SSH) |

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://terraform.io) >= 1.0.0
- AWS CLI configured with credentials
- An AWS account (costs ~$0.01/hour for t2.micro)

### Deploy

```bash
# Clone or copy this directory
cd cloud_breach_s3_terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy the scenario
terraform apply

# Note the output - especially target_ec2_ip
```

### Cleanup

```bash
terraform destroy -auto-approve
```

## 🎛️ Customization Options

### Security Toggle (Difficulty)

| Variable | Value | Effect |
|----------|-------|--------|
| `use_imdsv2` | `false` (default) | IMDSv1 - Vulnerable to SSRF |
| `use_imdsv2` | `true` | IMDSv2 - Requires session token |

### Network Restrictions

```hcl
# Restrict to your IP only (recommended)
allowed_cidr_blocks = ["YOUR_IP/32"]

# Open to all (default - less secure)
allowed_cidr_blocks = ["0.0.0.0/0"]
```

### SSH Access

```hcl
# Enable SSH for debugging
enable_ssh   = true
ssh_key_name = "your-key-pair-name"
```

## 🛡️ Defensive Lessons

After completing the scenario, implement these mitigations:

### 1. Use IMDSv2
```hcl
metadata_options {
  http_tokens = "required"  # Enforces IMDSv2
}
```

### 2. Restrict Reverse Proxy
```nginx
# Only allow specific Host headers
if ($http_host !~* ^(allowed-host\.com)$) {
    return 403;
}
```

### 3. Least Privilege IAM
```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject"],
  "Resource": ["arn:aws:s3:::specific-bucket/specific-path/*"]
}
```

### 4. Use VPC Endpoints
```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
}
```

## ⚠️ Disclaimer

This is an intentionally vulnerable environment for **educational purposes only**. 

- Deploy only in isolated AWS accounts
- Destroy resources when not in use
- Never use in production environments
- You are responsible for all AWS costs