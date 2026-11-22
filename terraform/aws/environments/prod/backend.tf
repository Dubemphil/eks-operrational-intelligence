# AWS S3 Remote State Backend Configuration (Prod)
terraform {
  backend "s3" {
    # Dynamically injected at runtime via GitHub Actions CI/CD or CLI:
    # - bucket         : secrets.TF_STATE_BUCKET
    # - key            : environments/prod/terraform.tfstate
    # - region         : eu-north-1
    # - dynamodb_table : secrets.TF_LOCK_TABLE (optional)
  }
}

