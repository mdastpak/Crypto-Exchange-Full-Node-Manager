# 13. Roadmap

Milestones in order of dependency. Each is a GitHub epic with its sub-issues; the decisions of [14-open-questions.md](14-open-questions.md) are issues with the label `decision`.

| Milestone | Epic | Depends on | Outcome |
| --- | --- | --- | --- |
| M0 Foundation | (see issues) | — | Repository skeleton, CI, configuration, database, outbox, audit, row seals, data keys, observability |
| M1 Full nodes | | M0 | Bitcoin, Ethereum, TRON nodes (mainnet and testnet) deployable with one command; node registry, health monitor, selector with failover |
| M2 Chain adapters | | M1 | One interface; UTXO, EVM, TRON implementations with integration tests on regtest and dev chains |
| M3 Keys and signer | | M0 | `fnm-signer` per family, Vault unwrap, signed policies, mTLS PKI, request signatures, ceremonies |
| M4 Addresses | | M2, M3 | Pool, independent verification, random allocation, lifecycle, address signatures, TRON import |
| M5 Deposits | | M2, M4 | Scanner, finality, reorgs, witness check, held deposits, events |
| M6 Withdrawals | | M2, M3 | Validation, planning per family, signing, broadcast, tracking, stuck transactions, FNM policies, kill switches |
| M7 Sweeps and treasury | | M5, M6 | Sweeps, top-ups, consolidation, hot/warm/cold rebalancing with approvals |
| M8 Integration | | M5, M6 | API and events for the exchange, admin routes, TRON shadow mode and migration, admin panel requirements |
| M9 Reconciliation and operations | | M5–M7 | Three reconciliations, alerts, runbooks, external security review |

M1 and M3 can proceed in parallel once M0 is in place.
