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
      "apt-get update",
      "apt-get install -y bash-completion dnsutils tinyproxy telnet",
      "grep -qxF 'Allow localhost' /etc/tinyproxy/tinyproxy.conf || echo 'Allow localhost' >> /etc/tinyproxy/tinyproxy.conf",
      "service tinyproxy restart"
  ])
  hub_subnet = "${module.hub_project.project_id}-subnet"
  shared_vpc_subnet = "shared-vpc-subnet"
  env_prefix = "${var.prefix}-${var.env_name}"
}

###############################################################################
#                          Hub, host and service projects                     #
###############################################################################

module "hub_project" {
  source          = "../../modules/project"
  project_create  = var.project_create != null
  billing_account = try(var.billing_account_id, null)
  oslogin         = try(var.project_create.oslogin, false)
  parent          = try(var.project_create.parent, null)
  prefix          = var.prefix
  name            = "hub"
  services = [
    "compute.googleapis.com",
    "container.googleapis.com"
  ]
  service_config = {
    disable_on_destroy         = false,
    disable_dependent_services = false
  }
}

module "spoke_project" { # is also spoke
  source          = "../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = local.env_prefix
  name            = "net"
  services        = concat(var.project_services, ["dns.googleapis.com"])
  shared_vpc_host_config = {
    enabled          = true
    service_projects = [] # defined later
  }
  iam = {
    "roles/owner" = var.owners_host
  }
}

module "svc_project" {
  source          = "../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = local.env_prefix
  name            = var.svc_project_name
  services        = var.project_services
  oslogin         = true
  oslogin_admins  = var.owners_svc
  shared_vpc_service_config = {
    attach       = true
    host_project = module.spoke_project.project_id
  }
  iam = {
    "roles/owner" = var.owners_svc
  }
}

################################################################################
#                                  Networking                                  #
################################################################################

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

# subnet IAM bindings control which identities can use the individual subnets

module "vpc-shared" { # is also spoke
  source     = "../../modules/net-vpc"
  project_id = module.spoke_project.project_id
  name       = "shared-vpc"
  subnets = [
    {
      ip_cidr_range      = var.ip_ranges.spoke
      name               = local.shared_vpc_subnet
      region             = var.region
      secondary_ip_range = {}
    }
  ]
  iam = {
    "${var.region}/${local.shared_vpc_subnet}" = {
      "roles/compute.networkUser" = concat(var.owners_svc, [
        "serviceAccount:${module.svc_project.service_accounts.cloud_services}",
      ])
    }
  }
}

module "vpc-shared-firewall" {
  source       = "../../modules/net-vpc-firewall"
  project_id   = module.spoke_project.project_id
  network      = module.vpc-shared.name
  admin_ranges = values(var.ip_ranges)
}

module "nat" {
  source         = "../../modules/net-cloudnat"
  project_id     = module.spoke_project.project_id
  region         = var.region
  name           = "vpc-shared"
  router_create  = true
  router_network = module.vpc-shared.name
}

module "hub-to-spoke-peering" {
  source                     = "../../modules/net-vpc-peering"
  local_network              = module.vpc-hub.self_link
  peer_network               = module.vpc-shared.self_link
  export_local_custom_routes = true
  export_peer_custom_routes  = false
}

################################################################################
#                                     DNS                                      #
################################################################################

module "host-dns" {
  source          = "../../modules/dns"
  project_id      = module.spoke_project.project_id
  type            = "private"
  name            = "example"
  domain          = "example.com."
  client_networks = [module.vpc-shared.self_link]
  recordsets = {
    "A localhost" = { ttl = 300, records = ["127.0.0.1"] }
    "A bastion"   = { ttl = 300, records = [module.vm-spoke.internal_ip] }
  }
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
  name       = "${module.vpc-shared.name}-spoke-test-vm"
  network_interfaces = [{
    network    = module.vpc-shared.self_link
    subnetwork = module.vpc-shared.subnet_self_links["${var.region}/${local.shared_vpc_subnet}"]
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
  name       = "${module.vpc-shared.name}-spoke-sa"
  iam_project_roles = {
    (module.spoke_project.project_id) = [
      "roles/container.developer",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}
