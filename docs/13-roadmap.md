# 13. Roadmap

Milestones in order of dependency. Each is a GitHub epic with its sub-issues; the decisions recorded in [14-open-questions.md](14-open-questions.md) are closed issues with the label `type: decision`. #41 (import of the exchange's TRON addresses) was dropped by decision #65.

| Milestone | Epic (sub-issues) | Depends on | Outcome |
| --- | --- | --- | --- |
| M0 Foundation | [#1](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/1) (#11, #13–#17, and #72 for the memo-aware schema) | — | Repository skeleton, CI, configuration, database, outbox, audit, row seals, data keys, observability |
| M1 Full nodes | [#2](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/2) (#18–#25) | M0 | Bitcoin, Ethereum, TRON nodes (mainnet and testnet) deployable with one command; node registry, health monitor, selector with failover |
| M2 Chain adapters | [#3](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/3) (#26–#30) | M1 | One interface; UTXO, EVM, TRON implementations with integration tests on regtest and dev chains |
| M3 Keys and signer | [#4](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/4) (#31–#36) | M0 | `fnm-signer` per family, Vault unwrap, signed policies, mTLS PKI, request signatures, ceremonies |
| M4 Addresses | [#5](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/5) (#37–#40) | M2, M3 | Pool, independent verification, random allocation, lifecycle, address signatures (memo allocation in M10) |
| M5 Deposits | [#6](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/6) (#42–#46) | M2, M4 | Scanner, finality, reorgs, witness check, held deposits, events |
| M6 Withdrawals | [#7](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/7) (#47–#52) | M2, M3 | Validation, planning per family, signing, broadcast, tracking, stuck transactions, FNM policies, kill switches |
| M7 Sweeps and treasury | [#8](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/8) (#53–#57) | M5, M6 | Sweeps, top-ups, consolidation, hot/warm/cold rebalancing with approvals |
| M8 Integration | [#9](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/9) (#58–#61) | M5, M6 | API and events for the exchange, admin routes, takeover of the exchange's TRON custody, admin panel requirements |
| M9 Reconciliation and operations | [#10](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/10) (#62–#64) | M5–M7 | Three reconciliations, alerts, runbooks, external security review |
| M10 Memo and tag networks | [#71](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/71) (#72–#78) | M5, M6 (#72 with M0) | TON, XRP, Stellar: shared deposit accounts, random never-reused memos, holds, memo withdrawals |
| M11 Network expansion | [#79](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/79) (#80–#82) | M9 | BSC, Polygon, Arbitrum, Litecoin, Dogecoin; then Solana |

M1 and M3 can proceed in parallel once M0 is in place.
