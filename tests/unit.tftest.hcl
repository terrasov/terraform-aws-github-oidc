mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }

  # Type-level default so every for_each instance yields valid JSON.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  deploy_roles = {
    "test-deploy" = {
      repository  = "terrasov/platform"
      branch      = "main"
      policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
    "test-env" = {
      repository  = "terrasov/platform"
      environment = "production"
      policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess", "arn:aws:iam::111122223333:policy/custom"]
    }
  }
}

run "roles_and_attachments" {
  command = plan

  assert {
    condition     = length(aws_iam_role.deploy) == 2
    error_message = "One role per deploy_roles entry."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.deploy) == 3
    error_message = "One attachment per (role, policy) pair."
  }

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 1
    error_message = "Provider created by default."
  }
}

run "no_provider_when_disabled" {
  command = plan

  variables {
    create_provider = false
  }

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 0
    error_message = "Provider must not be created when create_provider = false."
  }

  assert {
    condition     = local.provider_arn == "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
    error_message = "Provider ARN must be derived from the account when not created."
  }
}

run "rejects_branch_and_environment" {
  command = plan

  variables {
    deploy_roles = {
      "bad" = {
        repository  = "terrasov/platform"
        branch      = "main"
        environment = "production"
        policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      }
    }
  }

  expect_failures = [var.deploy_roles]
}

run "rejects_bad_repository_format" {
  command = plan

  variables {
    deploy_roles = {
      "bad" = {
        repository  = "not-a-repo"
        policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      }
    }
  }

  expect_failures = [var.deploy_roles]
}
