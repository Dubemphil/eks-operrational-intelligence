# AWS Storage Module: S3 Telemetry Archive, DLQ Quarantine & DynamoDB Audit Trail
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# 1. Telemetry Cold-Storage S3 Bucket (OTel Archive)
resource "aws_s3_bucket" "telemetry_archive" {
  bucket        = "omnipulse-telemetry-archive-${var.environment}-${var.account_id}"
  force_destroy = false

  tags = {
    Name        = "OmniPulse Telemetry Archive"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "telemetry_archive" {
  bucket = aws_s3_bucket.telemetry_archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "telemetry_archive" {
  bucket = aws_s3_bucket.telemetry_archive.id

  rule {
    id     = "archive-lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

# 2. DLQ Poison-Pill Quarantine S3 Bucket
resource "aws_s3_bucket" "dlq_quarantine" {
  bucket        = "omnipulse-dlq-quarantine-${var.environment}-${var.account_id}"
  force_destroy = false

  tags = {
    Name        = "OmniPulse DLQ Quarantine"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "dlq_quarantine" {
  bucket = aws_s3_bucket.dlq_quarantine.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. DynamoDB Immutable Audit Log Table for SRE Remediation Events
resource "aws_dynamodb_table" "remediation_audit" {
  name         = "omnipulse_remediation_audit_${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "incident_id"
  range_key    = "timestamp"

  attribute {
    name = "incident_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "failure_mode"
    type = "S"
  }

  global_secondary_index {
    name            = "failure_mode-index"
    hash_key        = "failure_mode"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "OmniPulse Remediation Audit Log"
    Environment = var.environment
  }
}

