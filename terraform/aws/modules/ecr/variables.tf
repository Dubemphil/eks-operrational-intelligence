variable "environment" {
  type        = string
  description = "Environment identifier"
  default     = "dev"
}

variable "repository_prefix" {
  type        = string
  description = "Prefix for ECR repositories"
  default     = "omnipulse"
}

variable "service_names" {
  type        = list(string)
  description = "List of microservice names to create ECR repositories for"
  default = [
    "frontend",
    "cartservice",
    "checkoutservice",
    "currencyservice",
    "emailservice",
    "paymentservice",
    "productcatalogservice",
    "recommendationservice",
    "shippingservice",
    "adservice",
    "loadgenerator",
    "microservice-app"
  ]
}

