# Changelog fragments

Every pull request that changes what operators or the exchange see adds one fragment here. The fragments are collected into `CHANGELOG.md` at each release and then deleted.

## Name

`<issue>.<type>.md`, for example `11.added.md`. When one issue needs two fragments of the same type, add a counter: `11.added.2.md`.

| Type | Use for |
| --- | --- |
| `added` | A new capability, endpoint, command, or configuration field |
| `changed` | A change of existing behaviour or configuration |
| `deprecated` | Something that still works but will be removed |
| `removed` | Something that no longer exists |
| `fixed` | A bug fix |
| `security` | A fix or hardening that matters for the custody's security |

## Content

One or more sentences in English, without headings, written for an operator: what changed and what they need to do, if anything.

## Exceptions

Changes that touch only documentation, CI, tests, or internal refactors may skip the fragment: label the pull request `no changelog`. Dependabot pull requests carry this label.

## Check

`scripts/check-changelog.sh` checks the names and contents of the fragments. In CI it also checks that a pull request adds one, unless it has the `no changelog` label:

```bash
scripts/check-changelog.sh origin/main
```
