

data "tfe_agent_pool" "this_pool" {
  count        = var.workspace_agents ? 1 : 0
  name         = var.agent_pool_name
  organization = var.organization
}

data "tfe_project" "this_project" {
  # disable this data source if we are creating a project or if project_id is provided
  count        = var.create_project || var.project_id != null ? 0 : 1
  name         = var.project_name
  organization = var.organization
}

###################################################
# Resources
## Workspace setup
resource "tfe_workspace" "this_ws" {
  name                      = var.workspace_name
  organization              = var.organization
  description               = var.workspace_description
  tag_names                 = var.workspace_tags
  terraform_version         = (var.workspace_terraform_version == "latest" ? null : var.workspace_terraform_version)
  working_directory         = (var.workspace_vcs_directory == "root_directory" ? null : var.workspace_vcs_directory)
  queue_all_runs            = var.queue_all_runs
  auto_apply                = var.workspace_auto_apply
  assessments_enabled       = var.assessments_enabled
  project_id                = var.create_project ? tfe_project.project[0].id : try(var.project_id, data.tfe_project.this_project[0].id)
  agent_pool_id             = var.workspace_agents ? data.tfe_agent_pool.this_pool[0].id : null
  execution_mode            = var.workspace_agents ? "agent" : var.execution_mode
  remote_state_consumer_ids = var.remote_state ? var.remote_state_consumers : null
  file_triggers_enabled     = var.file_triggers_enabled

  dynamic "vcs_repo" {
    for_each = lookup(var.vcs_repo, "identifier", null) == null ? [] : [var.vcs_repo]

    content {
      identifier         = lookup(vcs_repo.value, "identifier", null)
      branch             = lookup(vcs_repo.value, "branch", null)
      ingress_submodules = lookup(vcs_repo.value, "ingress_submodules", null)
      oauth_token_id     = lookup(vcs_repo.value, "oauth_token_id", null)
      tags_regex         = lookup(vcs_repo.value, "tags_regex", null)
      github_app_installation_id = lookup(vcs_repo.value, "github_app_installation_id", null)
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

## Variables
resource "tfe_variable" "variables" {
  for_each     = var.variables
  workspace_id = tfe_workspace.this_ws.id
  key          = each.key
  value        = each.value["value"]
  description  = lookup(each.value, "description", null)
  category     = lookup(each.value, "category", "terraform")
  sensitive    = lookup(each.value, "sensitive", false)
  hcl          = lookup(each.value, "hcl", false)
}

// Projects
resource "tfe_project" "project" {
  count        = var.create_project ? 1 : 0
  organization = var.organization
  name         = var.project_name
}