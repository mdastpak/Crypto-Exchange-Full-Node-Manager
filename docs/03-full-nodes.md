# 03. Full nodes

This document defines how the exchange's own nodes are deployed, configured, watched, and replaced. It is the first part to be built, because every other part depends on a node it can trust.

## Requirements common to every node

- **One node per host** (VM or bare metal), with local NVMe storage. Network storage is too slow for the state databases.
- **At least two nodes per network** in production (primary and secondary), on different hosts and preferably different providers or data centres, so that one failure, one corrupted database, or one upgrade never stops a network.
- **RPC only on the private network**, behind authentication (cookie, JWT secret, or RPC password from a secret file), never on a public interface. A firewall allows RPC only from the FNM core zone.
- **P2P open to the internet**, with a fixed inbound port, so the node has good peers.
- **Pinned versions.** Each image is pinned by version and digest in `deploy/nodes/<network>/compose.yaml`; upgrades are pull requests that follow the [upgrade procedure](#upgrades).
- **Health exposed** to the FNM node monitor through RPC; container metrics to Prometheus.
- **Testnet first.** Every network also has a testnet deployment (Bitcoin testnet4 or signet, Ethereum Sepolia or Holesky, TRON Nile or Shasta), used in CI and staging.

## Per network

The sizes below are planning estimates as of late 2026; they grow every month. Check the client's own documentation before ordering hardware and keep at least 40 percent free disk.

| Network | Clients | Mode | CPU / RAM | Disk (NVMe) | Notes |
| --- | --- | --- | --- | --- | --- |
| Bitcoin | Bitcoin Core | Full, not pruned, `txindex=0` | 4+ cores / 16 GB | ~1 TB | Pruning would stop rescans of old blocks; `txindex` is not needed, because FNM scans blocks and keeps its own UTXOs. ZMQ `rawblock` and `hashblock` for prompt notifications. |
| Ethereum | Execution: Geth (alternative Nethermind); Consensus: Lighthouse (alternative Teku) | Full (snap sync), not archive | 8+ cores / 32 GB | ~2–2.5 TB | Two clients per node, joined by a JWT secret. A minority client pair on the secondary node lowers the risk of one client's bug. `debug_traceBlockByNumber` must be enabled for ETH received through contracts (internal transfers). Checkpoint sync for the consensus client. |
| TRON | java-tron FullNode | Full (or Lite FullNode for the secondary) | 16 cores / 32–64 GB | ~3 TB+ (full) | JVM settings per the java-tron documentation. HTTP API and gRPC on the private network. Start from an official snapshot to avoid weeks of sync; verify the snapshot's checksum. |

EVM networks added later (BSC, Polygon, Arbitrum) follow the Ethereum pattern with their own clients; UTXO networks (Litecoin, Dogecoin) follow the Bitcoin pattern.

## Deployment layout

```text
deploy/nodes/
  README.md                  how to provision a node host
  common/                    host hardening, firewall rules, node-exporter, log shipping
  bitcoin/
    compose.yaml             bitcoind, pinned image
    bitcoin.conf.example     no secrets; rpcauth line generated per host
    .env.example
  ethereum/
    compose.yaml             geth + lighthouse, shared jwt secret
    geth.toml.example
    lighthouse.env.example
  tron/
    compose.yaml             java-tron
    config.conf.example      main or testnet configuration
  testnets/                  the same per testnet
```

Secrets (RPC passwords, the Engine API JWT) are generated on the host at provisioning, kept in files readable only by the container user, and given to FNM through its secret store, never committed.

A host is provisioned by a script (and later by Ansible or Terraform): harden the OS (SSH keys only, automatic security updates, no other services), mount the NVMe volume, open the firewall, install Docker, place the configuration, and start the compose project. The script is idempotent.

## Node registry

FNM keeps every node in the `nodes` table: network, role (`primary`, `secondary`, `witness`), kind (`own`, `provider`), RPC URL, credentials reference, capabilities (trace, ZMQ, websocket), and weight. Nodes are added by `fnmctl nodes add` or the admin API, audited.

## Health and selection

The node monitor polls each node every few seconds and records:

| Signal | Bitcoin | Ethereum | TRON |
| --- | --- | --- | --- |
| Synced | `getblockchaininfo.initialblockdownload == false`, `verificationprogress` | `eth_syncing == false`; consensus `/eth/v1/node/syncing` | `getnodeinfo` and block height |
| Head | `getbestblockhash` and height | `eth_blockNumber`, `latest` and `finalized` blocks | `getnowblock` |
| Lag | Head height against the highest head of our other nodes and of the reference providers |
| Peers | `getconnectioncount` | `net_peerCount`, consensus peers | `listnodes` |
| Fork | The hash at a recent height compared across nodes and providers |
| Latency and errors | Per RPC call, by method |
| Disk | Free space from node-exporter |

A node is **healthy** when it is synced, its head is within the network's lag threshold (for example 2 blocks for Bitcoin, 3 for Ethereum, 5 for TRON), its hash at `head - k` matches the majority, and its error rate is low. The scanner and the worker always read through the **node selector**, which returns the healthiest primary-role node and fails over to the next. When no own node is healthy:

- **Scanning stops** for that network (deposits are delayed, never credited from a provider alone).
- **Broadcasting** may use a provider, because a signed transaction is public anyway; this is configurable.
- An alert fires, and the network's state becomes `degraded` in the API, which the exchange shows as "deposits delayed" and uses to pause withdrawals.

## Upgrades

1. Read the release notes; note hard forks and their activation heights.
2. Upgrade the testnet node; run the adapter's integration tests against it.
3. Upgrade the secondary mainnet node; wait until it is healthy for a full day.
4. Upgrade the primary.
5. Hard forks: the upgrade must be done on every node before the activation height; FNM refuses to start a network whose nodes report a version below `min_version` from the configuration.

## Backups and recovery

Node data is not backed up: it can be rebuilt from the network. To avoid long resyncs, a periodic snapshot (filesystem snapshot of a stopped secondary) is kept per network. FNM's own database is backed up like the exchange's (WAL archiving, base backups, restore drill).

## Acceptance criteria for this phase

- `deploy/nodes/<network>` for Bitcoin, Ethereum, and TRON, mainnet and one testnet each, starts with one command on a fresh host.
- The node monitor reports synced, lag, peers, fork checks, and disk for each node, as metrics and through the API.
- Failover between two nodes of a network is shown by a test that stops the primary.
- The runbook in `docs/runbooks/` covers provisioning, upgrade, resync from snapshot, and disk full.
