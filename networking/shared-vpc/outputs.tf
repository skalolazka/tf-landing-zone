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

output "projects" {
  description = "Project ids."
  value = {
    host        = module.project-host.project_id
    service-svc = module.project-svc.project_id
  }
}

output "vms" {
  description = "Service VMs."
  value = {
    (module.vm-bastion.instance.name) = module.vm-bastion.internal_ip
  }
}

output "vpc" {
  description = "Shared VPC."
  value = {
    name    = module.vpc-shared.name
    subnets = module.vpc-shared.subnet_ips
  }
}

