/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


output "custom_role_id" {
  description = "Map of custom role IDs created in the organization."
  value = {
    for role_id, role in google_organization_iam_custom_role.roles :
    # build the string manually so that role IDs can be used as map
    # keys (useful for folder/organization/project-level iam bindings)
    (role_id) => "${var.organization_id}/roles/${role_id}"
  }
  depends_on = [
    google_organization_iam_custom_role.roles
  ]
}

output "custom_roles" {
  description = "Map of custom roles resources created in the organization."
  value       = google_organization_iam_custom_role.roles
}

output "firewall_policies" {
  description = "Map of firewall policy resources created in the organization."
  value = {
    for name, _ in var.firewall_policies :
    name => google_compute_organization_security_policy.policy[name]
  }
}

output "firewall_policy_id" {
  description = "Map of firewall policy ids created in the organization."
  value = {
    for name, _ in var.firewall_policies :
    name => google_compute_organization_security_policy.policy[name].id
  }
}

output "organization_id" {
  description = "Organization id dependent on module resources."
  value       = var.organization_id
  depends_on = [
    google_organization_iam_audit_config.config,
    google_organization_iam_binding.authoritative,
    google_organization_iam_custom_role.roles,
    google_organization_iam_member.additive,
    google_organization_iam_policy.authoritative,
    google_organization_policy.boolean,
    google_organization_policy.list
  ]
}

output "sink_writer_identities" {
  description = "Writer identities created for each sink."
  value = {
    for name, sink in google_logging_organization_sink.sink : name => sink.writer_identity
  }
}
