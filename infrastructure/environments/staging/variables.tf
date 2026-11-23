variable "project_name" {
  description = "Short name used in resource tags and name prefixes."
  type        = string
  default     = "pack-draft"
}

variable "environment" {
  description = "Deployment environment name (staging or production)."
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "environment must be staging or production."
  }
}

variable "aws_region" {
  description = "AWS region for this environment (ADR-002 defaults to us-east-1)."
  type        = string
  default     = "us-east-1"
}
