variable "oidc_provider_url" {
  description = "OIDC provider URL of the EKS cluster"
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN of the EKS cluster"
}

variable "role_name" {
  description = "Name of the IAM role to create"
}

variable "service_account_name" {
  description = "Kubernetes Service Account name that will assume this role"
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
}