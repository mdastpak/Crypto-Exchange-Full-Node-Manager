# Crypto Exchange Full Node Manager

The custody and blockchain-gateway service of the [Crypto Exchange](https://github.com/mdastpak/Crypto-Exchange). It runs and watches the exchange's own full nodes, and on top of them gives the exchange one interface to every network: address generation and allocation, deposits, withdrawals, sweeps, the hot, warm, and cold wallets, and the signers that hold the keys.

> [!WARNING]
> **Design stage.** This repository holds the specification only. Nothing here is ready to hold funds. The work is tracked in the [GitHub issues](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues), starting from the epics listed in the [roadmap](docs/13-roadmap.md).

## What it does

| Area | Summary | Document |
| --- | --- | --- |
| Full nodes | Deployment layout, hardware, configuration, health, failover, and upgrades of the nodes of each network (Bitcoin, Ethereum, TRON first) | [03-full-nodes.md](docs/03-full-nodes.md) |
| Chain adapters | One Go interface over the UTXO, EVM, TRON, and memo (TON, XRP, Stellar) families: derive, validate, scan, build, estimate, broadcast, confirm | [04-chain-adapters.md](docs/04-chain-adapters.md) |
| Wallets and keys | The key hierarchy, the wallet tiers (deposit, hot, warm, cold), the signers, key ceremonies, and backups | [05-wallets-and-keys.md](docs/05-wallets-and-keys.md) |
| Addresses | Watch-only derivation, a pre-generated pool, random allocation to users, memos and tags for shared-account networks, lifecycle, and verification | [06-address-management.md](docs/06-address-management.md) |
| Deposits | Block scanning, confirmations, reorgs, cross-checks against a second source, and events to the exchange | [07-deposits.md](docs/07-deposits.md) |
| Withdrawals | Fee estimation, nonces and UTXO selection, batching, signing under policy, broadcasting, and stuck transactions | [08-withdrawals.md](docs/08-withdrawals.md) |
| Sweeps and treasury | Sweeps of deposit addresses, gas top-ups, hot and cold rebalancing, and UTXO consolidation | [09-sweeps-and-treasury.md](docs/09-sweeps-and-treasury.md) |
| Security | Threat model, trust zones, internal and external encryption, request signing, approvals, and audit | [10-security.md](docs/10-security.md) |
| Integration | The API and events between this service, the exchange, and the admin panel | [11-integration-api.md](docs/11-integration-api.md) |
| Reconciliation and operations | On-chain balances against the books, metrics, alerts, and runbooks | [12-reconciliation-and-observability.md](docs/12-reconciliation-and-observability.md) |

Start with [01-vision-and-scope.md](docs/01-vision-and-scope.md) and [02-architecture.md](docs/02-architecture.md). The design decisions are recorded in [14-open-questions.md](docs/14-open-questions.md).

## Related repositories

| Repository | Role |
| --- | --- |
| [Crypto-Exchange](https://github.com/mdastpak/Crypto-Exchange) | The exchange backend: users, ledger, limits, AML, and the user-facing API. It calls this service for everything on chain. |
| [Crypto-Exchange-Admin-Panel](https://github.com/mdastpak/Crypto-Exchange-Admin-Panel) | The back office. It shows the nodes, the wallets, and the sweeps, and collects the approvals this service asks for. |

## Planned stack

The same stack as the exchange, so that code, operations, and reviews carry over: Go 1.26, PostgreSQL 16, RabbitMQ with a transactional outbox, Redis, Vault or OpenBao (Transit) for key wrapping, Prometheus and OpenTelemetry, Docker Compose for the nodes first.

## Contributing

All code, comments, and documentation are in English. Every change links its issue, and changes to keys, signers, or policies need the security review of the pull request template.

## License

[MIT](LICENSE).
