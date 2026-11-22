variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
  default     = "dev"
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name used for subnet tagging"
  default     = "omnipulse-eks"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

