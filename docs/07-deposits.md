# 07. Deposits

## Scanning

One scanner process per network reads every block from the selected own node, in order:

1. Get the next height. Compare the new block's parent hash with the stored hash of the previous height; a mismatch is a **reorg** (below).
2. Extract the transfers that touch watched addresses (deposit, hot, warm, cold) and registered assets only.
3. In one database transaction: store the block reference (height, hash, parent), insert or update the deposits, raise the confirmations of the open deposits, and write the outbox events.
4. Store the scan cursor. A crash re-scans from the cursor; every write is idempotent by `(network, tx_id, output_index or log_index)`.

The scanner starts at a configured height per network (the deployment height) and catches up at full speed, then follows the head, with ZMQ, websocket subscriptions, or polling.

## States

```text
detected -> pending (confirmations counting) -> final -> credited (acknowledged by the exchange)
                     \-> orphaned (reorged out)            \-> held (below minimum, unknown asset, quarantined address, witness mismatch)
```

| Event | When | Payload |
| --- | --- | --- |
| `DepositDetected` | First seen in a block (optional mempool `seen` for UTXO, display only) | network, asset, amount, address, owner_ref, tx_id, index, block, confirmations |
| `DepositConfirmationsChanged` | Each block, throttled | id, confirmations, required |
| `DepositFinalized` | Reached the network's finality, and passed the witness check | id, the same payload, final block hash |
| `DepositOrphaned` | Reorged out before final | id |
| `DepositHeld` | Needs review | id, reason |

The exchange credits only on `DepositFinalized` and acknowledges with `POST /v1/deposits/{id}/ack`; unacknowledged events are redelivered.

## Finality per network

| Network | Default | Notes |
| --- | --- | --- |
| Bitcoin | 3 confirmations; 6 above a configured amount | Configurable thresholds per asset |
| Ethereum and ERC-20 | The `finalized` tag | About 13 minutes |
| TRON and TRC-20 | 19 confirmations | Solidified block |
| Other EVM | Per network configuration | |

## Reorgs

The scanner keeps block hashes for `reorg_depth` blocks. On a parent mismatch it walks back to the common ancestor, marks every deposit in the dropped blocks `orphaned` (or back to `detected` if the transaction appears again in the new branch), restores UTXOs and nonces it affected, and re-scans forward. A reorg deeper than `reorg_depth`, or of a block already counted final, stops the network and alerts: it means the finality rule was wrong or the node is on a fork.

## Witness check

Before a deposit becomes final, if its value is above `witness_threshold` (configurable per asset, possibly zero), FNM asks an independent witness (a second own node on another client where possible, or a third-party provider) whether the same transaction, with the same recipient and amount, is in the same block. A mismatch holds the deposit and alerts. This protects against a single compromised or buggy node inventing deposits.

## Special cases

- **Tokens not in the registry, or dust**: recorded as `held` with reason `unsupported_asset` or `below_minimum`; never credited automatically; not swept automatically.
- **Deposits to hot, warm, or cold wallets** from outside: recorded as `held` for review (they belong to no user).
- **Internal transfers** (sweeps, top-ups, refills) between our own addresses are recognized by the transaction ids FNM itself broadcast and are not deposits.
- **Failed transactions** (EVM status 0, TRON `REVERT`) are never deposits.
- **Fake tokens**: a `Transfer` event from a contract that is not the registered one is ignored, whatever its symbol.
- **Several outputs or logs in one transaction**: each is a deposit of its own, keyed by its index.
