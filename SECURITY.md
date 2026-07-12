# Security policy

## Reporting a vulnerability

Email **support@terrasov.dev** with subject `SECURITY:`. In scope: anything in this
module's Terraform that weakens its posture — a control that can be silently disabled, an
insecure default, a misconfiguration the module permits, or a supply-chain concern in its
pinned providers.

Please include the module version (git tag) and a minimal reproduction.

- Acknowledgement within **2 business days**.
- We agree a fix and disclosure timeline with you; fixes ship as patch releases and are
  called out in `CHANGELOG.md`.
- No bug bounty is offered at this time; credit in the release notes is given on request.

## Supported versions

The latest major version receives security fixes. See `CHANGELOG.md` for the release history.

## Scope

This is one of TerraSov's open-source hardened modules — the same secure-by-default posture
as the private compliance library, without the framework crosswalk and CI gate. Security of
the TerraSov platform itself is documented at <https://terrasov.dev/security>.
