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

locals {
  env_prefix = "${var.prefix}-${var.env_name}"
}

module "hub_project" { # created in networking/hub
  source          = "../../modules/project"
  project_create  = false
  parent          = var.root_node
  prefix          = var.prefix
  name            = "hub" # TODO: move to var?
}

module "hub_project_vpc" { # created in networking/hub
  source     = "../../modules/net-vpc"
  vpc_create  = false
  project_id = module.hub_project.project_id
  name       = "${module.hub_project.project_id}-vpc"
}

module "host_project" { # spoke to hub and host to the shared VPC
  source          = "../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = local.env_prefix
  name            = "host"
  services        = concat(var.project_services, ["dns.googleapis.com"])
  shared_vpc_host_config = {
    enabled          = true
    service_projects = []
  }
  iam = {
    "roles/owner" = var.owners
  }
}

module "host_project_vpc" {
  source     = "../../modules/net-vpc"
  project_id = module.host_project.project_id
  name       = "${local.env_prefix}-host-project-vpc"
  subnets    = [ # TODO: multiple with regions
    {
      ip_cidr_range      = var.subnet_ip_range
      name               = "${local.env_prefix}-${var.region}-subnet"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "hub_to_host_peering" {
  source                     = "../../modules/net-vpc-peering"
  local_network              = module.hub_project_vpc.self_link
  peer_network               = module.host_project_vpc.self_link
  export_local_custom_routes = true
  export_peer_custom_routes  = false
}

module "host_project_firewall" {
  source       = "../../modules/net-vpc-firewall"
  project_id   = module.host_project.project_id
  network      = module.host_project_vpc.name
  ssh_source_ranges = ["35.235.240.0/20"] # IAP
  admin_ranges = var.firewall_ip_ranges
}

module "service_project" {
  for_each        = toset(var.app_projects)
  source          = "../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = local.env_prefix
  name            = "service-${each.key}"
  services        = var.project_services
  oslogin         = true
  shared_vpc_service_config = {
    attach       = true
    host_project = module.host_project.project_id
  }
  iam = {
    "roles/owner" = var.owners
  }
}