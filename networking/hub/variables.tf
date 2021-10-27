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

variable "owners" {
  description = "Project owners, in IAM format."
  type        = list(string)
  default     = []
}

variable "prefix" {
  description = "Prefix used for resources that need unique names ('prefix-name')."
  type        = string
}

variable "hub_services" {
  description = "Service APIs enabled in the hub project."
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

variable "subnet_ip_range" { # TODO: multiple ranges mapped to regions
  description = "IP CIDR range for the hub subnet."
  type        = string
  default     = "10.0.0.0/24"
}

variable "firewall_ip_ranges" { # TODO: multiple?
  description = "IP CIDR ranges to open in the firewall."
  type        = list(string)
  default     = ["10.0.16.0/24"] # see networking/dev/variables.tf, subnet_ip_range variable
}