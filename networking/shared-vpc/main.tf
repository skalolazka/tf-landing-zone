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
  shared_vpc_subnet = "shared-vpc-subnet"
}

###############################################################################
#                          Host and service projects                          #
###############################################################################

module "project-host" {
  source          = "../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
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

module "project-svc" {
  source          = "../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = var.svc_project_name
  services        = var.project_services
  oslogin         = true
  oslogin_admins  = var.owners_svc
  shared_vpc_service_config = {
    attach       = true
    host_project = module.project-host.project_id
  }
  iam = {
    "roles/owner" = var.owners_svc
  }
}

################################################################################
#                                  Networking                                  #
################################################################################

# subnet IAM bindings control which identities can use the individual subnets

module "vpc-shared" {
  source     = "../../modules/net-vpc"
  project_id = module.project-host.project_id
  name       = "shared-vpc"
  subnets = [
    {
      ip_cidr_range      = var.ip_ranges.svc
      name               = local.shared_vpc_subnet
      region             = var.region
      secondary_ip_range = {}
    }
  ]
  iam = {
    "${var.region}/${local.shared_vpc_subnet}" = {
      "roles/compute.networkUser" = concat(var.owners_svc, [
        "serviceAccount:${module.project-svc.service_accounts.cloud_services}",
      ])
    }
  }
}

module "vpc-shared-firewall" {
  source       = "../../modules/net-vpc-firewall"
  project_id   = module.project-host.project_id
  network      = module.vpc-shared.name
  admin_ranges = values(var.ip_ranges)
}

module "nat" {
  source         = "../../modules/net-cloudnat"
  project_id     = module.project-host.project_id
  region         = var.region
  name           = "vpc-shared"
  router_create  = true
  router_network = module.vpc-shared.name
}

################################################################################
#                                     DNS                                      #
################################################################################

module "host-dns" {
  source          = "../../modules/dns"
  project_id      = module.project-host.project_id
  type            = "private"
  name            = "example"
  domain          = "example.com."
  client_networks = [module.vpc-shared.self_link]
  recordsets = {
    "A localhost" = { ttl = 300, records = ["127.0.0.1"] }
    "A bastion"   = { ttl = 300, records = [module.vm-bastion.internal_ip] }
  }
}

################################################################################
#                                     VM                                      #
################################################################################

module "vm-bastion" {
  source     = "../../modules/compute-vm"
  project_id = module.project-svc.project_id
  zone       = "${var.region}-b"
  name       = "bastion"
  network_interfaces = [{
    network    = module.vpc-shared.self_link
    subnetwork = lookup(module.vpc-shared.subnet_self_links, "${var.region}/${local.shared_vpc_subnet}", null)
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  tags = ["ssh"]
  metadata = {
    startup-script = join("\n", [
      "#! /bin/bash",
      "apt-get update",
      "apt-get install -y bash-completion dnsutils tinyproxy telnet",
      "grep -qxF 'Allow localhost' /etc/tinyproxy/tinyproxy.conf || echo 'Allow localhost' >> /etc/tinyproxy/tinyproxy.conf",
      "service tinyproxy restart"
    ])
  }
  service_account_create = true
}
