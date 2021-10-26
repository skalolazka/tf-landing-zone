# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "billing_account_id" {
  description = "Billing account id used as default for new projects."
  type        = string
}

variable "ip_ranges" {
  description = "Subnet IP CIDR ranges."
  type        = map(string)
  default = {
    hub     = "10.0.0.0/24"
    spoke   = "10.0.16.0/24"
  }
}

variable "owners_svc" {
  description = "Service project owners, in IAM format."
  type        = list(string)
  default     = []
}

variable "owners_host" {
  description = "Host project owners, in IAM format."
  type        = list(string)
  default     = []
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
}

variable "env_name" {
  description = "Environment name (for example, dev). Will be put into resource names when needed."
  type        = string
}

variable "svc_project_name" {
  description = "Project name for the service project (without the prefix)"
  type        = string
}

variable "project_services" {
  description = "Service APIs enabled by default in new projects."
  type        = list(string)
  default = [
    "container.googleapis.com",
    "stackdriver.googleapis.com",
    "compute.googleapis.com"
  ]
}

variable "region" {
  description = "Region used."
  type        = string
  default     = "europe-west1"
}

variable "root_node" {
  description = "Hierarchy node where projects will be created, 'organizations/org_id' or 'folders/folder_id'."
  type        = string
}

variable "project_create" {
  description = "Set to non null if the hub project needs to be created."
  type = object({
    oslogin         = bool
    parent          = string
  })
  default = null
  validation {
    condition = (
      var.project_create == null
      ? true
      : can(regex("(organizations|folders)/[0-9]+", var.project_create.parent))
    )
    error_message = "Project parent must be of the form folders/folder_id or organizations/organization_id."
  }
}
