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

# Attention: ideally prefix should be with the env name,
# since projects have to have different names in different envs
prefix = "vb2-dev"
# here specify the env folder
#root_node = "folders/165712254582" # dev
root_node = "folders/976258297720" # dev in vb-fabric-2
#root_node = "folders/213486208149" # test
#root_node = "folders/989630407090" # prod
svc_project_name = "sanipa1"
ip_ranges = { svc = "10.1.0.0/24"}