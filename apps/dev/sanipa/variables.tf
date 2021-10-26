variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
}

variable "env_name" {
  description = "Environment name (for example, dev). Will be put into resource names when needed."
  type        = string
}

variable "region" {
  description = "Region used."
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Zone used."
  type        = string
  default     = "europe-west1-c"
}

variable "app_name" {
  description = "Application name."
  type        = string
}

