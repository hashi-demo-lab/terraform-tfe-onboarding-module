output "workspace_id" {
  description = "ID of managed workspace"
  value       = tfe_workspace.this_ws.id
}

output "workspace_name" {
  description = "Name of managed workspace"
  value       = tfe_workspace.this_ws.name
}

output "project_id" {
  description = "ID of managed project"
  value       = var.project_id
  
}