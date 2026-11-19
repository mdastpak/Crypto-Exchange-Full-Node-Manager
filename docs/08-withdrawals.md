# 08. Withdrawals

The exchange decides whether a withdrawal may happen (second factor, limits, AML, review, funds locked in the ledger). FNM decides how to pay it and checks it again against its own policy.

## Request

`POST /v1/withdrawals`, signed by the exchange, with:

| Field | Meaning |
| --- | --- |
| `idempotency_key` | Unique per withdrawal; a repeat returns the same withdrawal; a different body with the same key is `409` |
| `network`, `asset` | From the registry |
| `to` | Destination, validated by the adapter; memo or tag where the network needs it |
| `amount` | Integer, smallest unit |
| `fee_policy` | `normal` or `priority`; the exchange has already charged the user its fee |
| `exchange_approval` | The exchange's approval record id; for amounts above the review threshold, the ids of the approving staff |

## Processing

```text
received -> validated -> planned -> signing -> signed -> broadcast -> confirming -> completed
                \-> rejected (policy)          \-> failed (on chain) / replaced / expired-and-rebuilt
```

1. **Validate**: address, asset, amount above the network minimum, destination not a contract we refuse (for example the token's own contract), not one of our deposit addresses (an internal transfer is handled by the exchange's ledger, not on chain), FNM's own caps and velocity per asset.
2. **Plan**: pick the paying hot wallet; for UTXO, select coins (branch-and-bound, then largest-first) and add change; for EVM, allocate the nonce under a row lock; for TRON, set the reference block and expiry. Estimate the fee within the ceiling. Reserve the UTXOs or the nonce.
3. **Batch** (UTXO, optional): withdrawals queued within a short window are paid by one transaction with many outputs, which lowers fees. EVM and TRON pay one by one.
4. **Sign**: send the plan to the signer, which rebuilds, checks policy, signs, and records it. The signed transaction is stored before it is broadcast.
5. **Broadcast** through at least two healthy nodes (and a provider if configured). A broadcast error that means "already known" is success.
6. **Track** until finality; emit `WithdrawalBroadcast` (with tx id), `WithdrawalConfirmed`, or `WithdrawalFailed`.

## Stuck and failed transactions

- **Bitcoin**: after a configurable time without confirmation, fee bump by RBF (same inputs, higher fee); the replacement is a new attempt of the same withdrawal, and only one can confirm.
- **EVM**: replace with the same nonce and +10 percent or more on both fee fields; a nonce gap (a lower nonce never mined) blocks the hot wallet and alerts.
- **TRON**: a transaction not in a block after its expiry is rebuilt and signed again under the same withdrawal.
- **Failed on chain** (EVM revert, TRON out of energy): `WithdrawalFailed` with the reason; the exchange decides to retry (new key) or release the funds. The fee spent is reported.

Every attempt is a row under its withdrawal; at most one attempt of a withdrawal can be valid on chain at a time (same inputs or same nonce), so a withdrawal is never paid twice.

## Policies in FNM (independent of the exchange)

- Per asset: maximum per transaction, per day, per destination per day.
- Global velocity: if withdrawals in the last hour exceed a threshold, new ones wait for a staff approval.
- First-time destinations above an amount wait a configured delay.
- A kill switch per network and globally (`fnmctl withdrawals pause`), also exposed to the admin panel.

## Hot wallet insufficient

When the hot wallet cannot pay, the withdrawal waits in `planned` with reason `insufficient_hot_balance`, FNM requests a refill from warm (see [09](09-sweeps-and-treasury.md)), and the exchange is told by `WithdrawalDelayed`.
