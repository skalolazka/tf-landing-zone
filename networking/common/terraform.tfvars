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

billing_account_id = "01894F-FA7D6D-2F89BF"

owners_host = ["user:nstrelkova@google.com"]
owners_svc = ["user:nstrelkova@google.com"]

prefix = "vb3"
# Attention: ideally prefix should be with the env name,
# since projects have to have different names in different envs
env_name = "dev"

project_create = {
    oslogin         = false
    parent          = "folders/731950865872" # root node, vb-fabric-3
}

ip_ranges = {
    hub     = "10.0.0.0/24"
    spoke   = "10.1.0.0/24"
}

# here specify the env folder
root_node = "folders/1029609482939" # dev in vb-fabric-3
svc_project_name = "sanipa" # project to host the app
