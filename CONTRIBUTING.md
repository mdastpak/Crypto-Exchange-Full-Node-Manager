# Contributing

This service holds the keys of the exchange. Every rule below exists so that no single mistake, and no single person, can move funds.

## Language

All code, comments, commit messages, issues, pull requests, and documentation are in English ([#70](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/70), D11).

## Branches and pull requests

- `main` is the only long-lived branch. It is protected: changes reach it only through pull requests with green CI and an approving review.
- Branch from an up-to-date `main`, one branch per issue. After your pull request merges, run `scripts/sync-main.sh` to fast-forward `main` and delete merged local branches.
- Every pull request links its issue (`Fixes #<n>`) and fills in the [pull request template](.github/PULL_REQUEST_TEMPLATE.md). The security review section is required for changes to keys, signers, policies, addresses, withdrawals, sweeps, migrations, or configuration validation.
- [CODEOWNERS](.github/CODEOWNERS) lists who must approve which paths. The signer, signing policies, keys, migrations, and the CI workflows need the custody owner.

## Commit messages

Write the message in a file and commit with `git commit -F <file>`, not with `-m`. This keeps a subject line of at most 72 characters, a blank line, and a body that explains why, wrapped at 72 columns, and it avoids shell quoting mistakes in long messages:

```text
Add the node registry table and fnmctl commands

The registry is the only source of node endpoints; the scanner and the
worker read it through the node selector.

Refs #22
```

Use the imperative mood ("Add", "Fix"), one logical change per commit, and never commit secrets, seeds, keys, or `.env` files.

## Changelog

Add a fragment to [changelog.d](changelog.d/README.md) for every change that operators or the exchange will notice. CI checks it.

## Checks

CI runs these on every pull request; run them locally before you push:

```bash
gofmt -l .
go vet ./...
go build ./...
go test -race ./...
go run golang.org/x/vuln/cmd/govulncheck@v1.9.0 ./...
npx markdownlint-cli2 "**/*.md"
scripts/check-changelog.sh origin/main
docker build -f deploy/fnm/fnm-api/Dockerfile -t fnm/fnm-api .
```

The required checks for merges into `main` are: `go`, `govulncheck`, `markdown`, `changelog`, and `docker (<binary>)` for each of `fnm-api`, `fnm-worker`, `fnm-scanner`, `fnm-signer`, and `fnmctl`.

## Images

Each binary has its own image under `deploy/fnm/<binary>/Dockerfile`: a static build on a distroless base, running as a non-root user, with every base image pinned by digest. Dependabot proposes digest updates; review them like any other change.

## Dependencies

FNM does not import code from the exchange; shared code is copied and adapted ([#70](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/70), D7). Add a Go module only when it is needed, and prefer the standard library and well-audited libraries. `go.sum` is committed and verified in CI and in every image build.

## Security issues

Do not open a public issue for a vulnerability. Report it privately to the repository owner through GitHub's private vulnerability reporting.
