locals {
  env_prefix = "${var.prefix}-${var.env_name}"
}

module "host_project" {
  source          = "../../../modules/project"
  project_create  = false
  prefix          = local.env_prefix
  name            = "host"
}

module "host_project_vpc" {
  source     = "../../../modules/net-vpc"
  vpc_create  = false
  project_id = module.host_project.project_id
  name       = "${local.env_prefix}-host-project-vpc"
}

#redo to use module
data "google_compute_subnetwork" "host_project_vpc_subnet" {
  project = module.host_project.project_id
  name   = "${local.env_prefix}-${var.region}-subnet"
  region = var.region
}

module "compute-vm" {
  source     = "../../../modules/compute-vm"
  project_id = "${local.env_prefix}-service-${var.app_name}"
  zone       = var.zone
  name       = "${local.env_prefix}-${var.app_name}"
  network_interfaces = [{
    network    = module.host_project_vpc.self_link
    subnetwork = data.google_compute_subnetwork.host_project_vpc_subnet.self_link
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  tags         = ["ssh"]
}
