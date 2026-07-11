variable "create_provider" {
  description = "Create the GitHub OIDC identity provider. Set false if the account already has one (it is account-unique)."
  type        = bool
  default     = true
}

variable "deploy_roles" {
  description = <<-EOT
    Deploy roles to create, keyed by role name. Each role trusts GitHub Actions tokens
    for exactly one repository, optionally restricted to a branch or environment.
    policy_arns are attached as-is — pass least-privilege policies, not AdministratorAccess.
  EOT
  type = map(object({
    repository        = string           # org/repo
    branch            = optional(string) # restrict to refs/heads/<branch>
    environment       = optional(string) # restrict to a GitHub environment
    policy_arns       = list(string)
    max_session_hours = optional(number, 1)
  }))

  validation {
    condition     = alltrue([for r in var.deploy_roles : can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", r.repository))])
    error_message = "repository must be in org/repo format."
  }

  validation {
    condition     = alltrue([for r in var.deploy_roles : !(r.branch != null && r.environment != null)])
    error_message = "Restrict by branch OR environment, not both."
  }

  validation {
    condition     = alltrue([for r in var.deploy_roles : length(r.policy_arns) > 0])
    error_message = "Each role needs at least one policy ARN."
  }
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}
