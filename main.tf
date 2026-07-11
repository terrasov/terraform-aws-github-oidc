data "aws_partition" "this" {}
data "aws_caller_identity" "this" {}

locals {
  tags = merge(var.tags, {
  })

  github_oidc_url = "token.actions.githubusercontent.com"

  provider_arn = var.create_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:${data.aws_partition.this.partition}:iam::${data.aws_caller_identity.this.account_id}:oidc-provider/${local.github_oidc_url}"

  # sub claim per role: branch- or environment-scoped, falling back to any ref of the repo.
  role_subjects = {
    for name, role in var.deploy_roles : name => (
      role.branch != null ? "repo:${role.repository}:ref:refs/heads/${role.branch}" :
      role.environment != null ? "repo:${role.repository}:environment:${role.environment}" :
      "repo:${role.repository}:*"
    )
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_provider ? 1 : 0

  url             = "https://${local.github_oidc_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  tags = local.tags
}

data "aws_iam_policy_document" "trust" {
  for_each = var.deploy_roles

  statement {
    sid     = "GitHubActionsOidc"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_url}:sub"
      values   = [local.role_subjects[each.key]]
    }
  }
}

resource "aws_iam_role" "deploy" {
  for_each = var.deploy_roles

  name                 = each.key
  description          = "TerraSov OIDC deploy role for ${each.value.repository} (no long-lived credentials)."
  assume_role_policy   = data.aws_iam_policy_document.trust[each.key].json
  max_session_duration = each.value.max_session_hours * 3600

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "deploy" {
  for_each = {
    for pair in flatten([
      for name, role in var.deploy_roles : [
        for idx, arn in role.policy_arns : {
          key  = "${name}:${idx}"
          name = name
          arn  = arn
        }
      ]
    ]) : pair.key => pair
  }

  role       = aws_iam_role.deploy[each.value.name].name
  policy_arn = each.value.arn
}
