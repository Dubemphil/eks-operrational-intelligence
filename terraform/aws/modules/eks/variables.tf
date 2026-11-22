variable "environment" {
  type        = string
  description = "Environment identifier"
  default     = "dev"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS Cluster"
  default     = "omnipulse-eks"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes Version"
  default     = "1.31"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where cluster is provisioned"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for node groups"
}

variable "instance_types" {
  type        = list(string)
  description = "EC2 Instance types for EKS worker nodes"
  default     = ["t3.xlarge"]
}

variable "capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT"
  default     = "ON_DEMAND"
}

variable "desired_node_count" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 3
}

variable "min_node_count" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 2
}

variable "max_node_count" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 5
}

