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
  vm-instances = [
    module.vm-hub.instance,
    module.vm-spoke.instance
  ]
  vm-startup-script = join("\n", [
    "#! /bin/bash",
    "apt-get update && apt-get install -y bash-completion dnsutils kubectl"
  ])
  hub_subnet = "${module.hub_project.project_id}-subnet"
  shared_vpc_subnet = "shared-vpc-subnet"
}

###############################################################################
#                                   project                                   #
###############################################################################

module "hub_project" {
  source          = "../../modules/project"
  project_create  = var.project_create != null
  billing_account = try(var.project_create.billing_account, null)
  oslogin         = try(var.project_create.oslogin, false)
  parent          = try(var.project_create.parent, null)
  name            = var.hub_project_id
  services = [
    "compute.googleapis.com",
    "container.googleapis.com"
  ]
  service_config = {
    disable_on_destroy         = false,
    disable_dependent_services = false
  }
}

module "spoke_project" {
  source          = "../../modules/project"
  project_create  = false
  name            = var.spoke_project_id
  services = [
    "compute.googleapis.com",
    "container.googleapis.com"
  ]
  service_config = {
    disable_on_destroy         = false,
    disable_dependent_services = false
  }
}

################################################################################
#                                Hub networking                                #
################################################################################

module "vpc-hub" {
  source     = "../../modules/net-vpc"
  project_id = module.hub_project.project_id
  name       = module.hub_project.project_id
  subnets    = [
    {
      ip_cidr_range      = var.ip_ranges.hub
      name               = local.hub_subnet
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "nat-hub" {
  source         = "../../modules/net-cloudnat"
  project_id     = module.hub_project.project_id
  region         = var.region
  name           = module.vpc-hub.name
  router_name    = module.vpc-hub.name
  router_network = module.vpc-hub.self_link
}

module "vpc-hub-firewall" {
  source       = "../../modules/net-vpc-firewall"
  project_id   = module.hub_project.project_id
  network      = module.vpc-hub.name
  admin_ranges = values(var.ip_ranges)
}

################################################################################
#                              Spoke networking                              #
################################################################################

module "vpc-spoke" {
  source     = "../../modules/net-vpc"
  project_id = module.spoke_project.project_id
  name       = var.spoke_vpc_name
  # the subnet should already exist from the previous tf
  #subnets    = [
  #  {
  #    ip_cidr_range      = var.ip_ranges.spoke
  #    #name               = "${var.spoke_vpc_name}-subnet-for-hub"
  #    name = local.shared_vpc_subnet
  #    region             = var.region
  #    secondary_ip_range = {}
  #  }
  #]
  vpc_create = false
}

# this has already been created via the shared vpc tf
#module "vpc-spoke-firewall" {
#  source       = "../../modules/net-vpc-firewall"
#  project_id   = module.spoke_project.project_id
#  network      = module.vpc-spoke.name
#  admin_ranges = values(var.ip_ranges)
#}

# same here
#module "nat-spoke" {
#  source         = "../../modules/net-cloudnat"
#  project_id     = module.spoke_project.project_id
#  region         = var.region
#  name           = "${local.prefix}spoke"
#  router_name    = "${local.prefix}spoke"
#  router_network = module.vpc-spoke.self_link
#}

module "hub-to-spoke-peering" {
  source                     = "../../modules/net-vpc-peering"
  local_network              = module.vpc-hub.self_link
  peer_network               = module.vpc-spoke.self_link
  export_local_custom_routes = true
  export_peer_custom_routes  = false
}

################################################################################
#                                   Test VMs                                   #
################################################################################

module "vm-hub" {
  source     = "../../modules/compute-vm"
  project_id = module.hub_project.project_id
  zone       = "${var.region}-b"
  name       = "${module.vpc-hub.name}-hub-test-vm"
  network_interfaces = [{
    network    = module.vpc-hub.self_link
    subnetwork = module.vpc-hub.subnet_self_links["${var.region}/${local.hub_subnet}"]
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  metadata               = { startup-script = local.vm-startup-script }
  service_account        = module.service-account-gce-hub.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  tags                   = ["ssh"]
}

module "vm-spoke" {
  source     = "../../modules/compute-vm"
  project_id = module.spoke_project.project_id
  zone       = "${var.region}-b"
  name       = "${module.vpc-spoke.name}-spoke-test-vm"
  network_interfaces = [{
    network    = module.vpc-spoke.self_link
    #subnetwork = module.vpc-spoke.subnet_self_links["${var.region}/${var.spoke_vpc_name}-subnet-for-hub"]
    #subnetwork = module.vpc-spoke.subnet_self_links["${var.region}/${local.shared_vpc_subnet}"]
    subnetwork = "${var.region}/${local.shared_vpc_subnet}"
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  metadata               = { startup-script = local.vm-startup-script }
  service_account        = module.service-account-gce-spoke.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  tags                   = ["ssh"]
}

module "service-account-gce-hub" {
  source     = "../../modules/iam-service-account"
  project_id = module.hub_project.project_id
  name       = "${module.vpc-hub.name}-hub-sa"
  iam_project_roles = {
    (module.spoke_project.project_id) = [
      "roles/container.developer",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}

module "service-account-gce-spoke" {
  source     = "../../modules/iam-service-account"
  project_id = module.spoke_project.project_id
  name       = "${module.vpc-spoke.name}-spoke-sa"
  iam_project_roles = {
    (module.spoke_project.project_id) = [
      "roles/container.developer",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}