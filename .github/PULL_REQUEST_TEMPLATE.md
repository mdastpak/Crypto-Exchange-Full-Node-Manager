## Summary

## Related issues

Fixes #

## How it was tested

## Security review

<!-- Required when the change touches keys, signers, policies, addresses, withdrawals, sweeps, migrations, or configuration validation. Otherwise write "Not applicable". -->

- [ ] **Threat:** what an attacker, a careless operator, a compromised exchange server, or a lying node could do with this change, and what stops them.
- [ ] **Funds:** no path can pay twice, sign outside policy, or send to an address the custody does not control or the request did not name.
- [ ] **Failure mode:** when a node, the signer, PostgreSQL, RabbitMQ, or Vault is down or slow, the change fails closed.
- [ ] **Multi-instance:** correct with several instances, during a rolling deployment, and after a restart at any step.
- [ ] **Secrets:** no key material, credential, or owner reference is logged, returned, or stored in clear.

## Checklist

- [ ] `gofmt -l .` is empty; `go vet ./...`, `go build ./...`, and `go test -race ./...` pass.
- [ ] A fragment is added in `changelog.d/`, or the pull request has the `no changelog` label.
- [ ] Migrations have up and down files; no merged migration was modified.
- [ ] Documentation in `docs/` is updated when behaviour or configuration changes.
- [ ] All code, comments, and text are in English.
- [ ] Commit messages follow [CONTRIBUTING.md](../CONTRIBUTING.md#commit-messages).
