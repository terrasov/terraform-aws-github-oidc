# terraform-aws-github-oidc

GitHub Actions → AWS federation without stored credentials: the OIDC identity provider plus
per-repository deploy roles whose trust policies pin the exact repository and optionally a
branch or GitHub environment. Kills long-lived `AWS_ACCESS_KEY_ID` secrets in CI.

- `sub` claim pinned per repo (`repo:org/repo:*`), branch (`:ref:refs/heads/main`) or
  environment (`:environment:production`)
- `aud` locked to `sts.amazonaws.com`
- Short sessions (1h default)
- No "admin shortcut" — you pass least-privilege policy ARNs explicitly

## Usage

```hcl
module "cicd" {
  source  = "terrasov/github-oidc/aws"
  version = "~> 1.0"

  deploy_roles = {
    "platform-deploy" = {
      repository  = "acme/platform"
      branch      = "main"
      policy_arns = [aws_iam_policy.deploy.arn]
    }
  }
}
```

Set `create_provider = false` if the account already has the GitHub OIDC provider (it is
account-unique).

Tests: native `terraform test` with a mocked provider.

## Compliance mapping (the paid layer)

This module is the generic core of [TerraSov](https://terrasov.dev)'s `cicd-oidc`. The
subscription adds **ISO 27001 / BSI C5 / ENS** clause annotations, a PR-blocking compliance
gate with control-referenced comments, auditor evidence guides, and 7 further modules for
the full EU sovereignty baseline on AWS.

## License

Apache-2.0
