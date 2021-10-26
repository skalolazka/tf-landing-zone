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

# Disclaimer: be careful with choosing project names, if you end up
# needing to destroy and then apply again, most probably it won't
# be able to create a project with the same name

project_create = {
    billing_account = "01894F-FA7D6D-2F89BF"
    oslogin         = false
    parent          = "folders/686622048913"
}

ip_ranges = {
    hub     = "10.0.0.0/24"
    #spoke   = "10.0.16.0/24"
    #spoke   = "10.0.32.0/24"
    #spoke   = "10.0.48.0/24"
    spoke = "10.1.0.0/24"
    #spoke-2 = "10.0.32.0/24"
}

hub_project_id = "vb2-hub"
spoke_project_id = "vb2-dev-net"
spoke_vpc_name = "shared-vpc"