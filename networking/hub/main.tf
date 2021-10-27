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

module "hub_project" {
  source          = "../../modules/project"
  billing_account = try(var.billing_account_id, null)
  oslogin         = false
  parent          = var.root_node
  prefix          = var.prefix
  name            = "hub" # "prefix-name"
  services        = var.hub_services
  service_config = {
    disable_on_destroy         = false,
    disable_dependent_services = false
  }
  iam = {
    "roles/owner" = var.owners
  }
}

module "hub_project_vpc" {
  source     = "../../modules/net-vpc"
  project_id = module.hub_project.project_id
  name       = "${module.hub_project.project_id}-vpc"
  # TODO: mulptiple, something like: subnets = [for region, range in var.ip_ranges : region -> range ]
  subnets    = [
    {
      ip_cidr_range      = var.subnet_ip_range
      name               = "${module.hub_project.project_id}-${var.region}-subnet"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "hub_vpc_firewall" {
  source       = "../../modules/net-vpc-firewall"
  project_id   = module.hub_project.project_id
  network      = module.hub_project_vpc.name
  ssh_source_ranges = ["35.235.240.0/20"] # IAP
  admin_ranges = var.firewall_ip_ranges
}