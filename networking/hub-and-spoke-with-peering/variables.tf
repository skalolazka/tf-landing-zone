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

variable "ip_ranges" {
  description = "IP CIDR ranges."
  type        = map(string)
  default = {
    hub     = "10.0.0.0/24"
    spoke   = "10.0.16.0/24"
  }
}

variable "project_create" {
  description = "Set to non null if project needs to be created."
  type = object({
    billing_account = string
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

variable "hub_project_id" {
  description = "Hub project id."
  type        = string
}

variable "spoke_project_id" {
  description = "Spoke project id."
  type        = string
}

variable "spoke_vpc_name" {
  description = "Spoke VPC name."
  type        = string
}

variable "region" {
  description = "VPC region."
  type        = string
  default     = "europe-west1"
}
