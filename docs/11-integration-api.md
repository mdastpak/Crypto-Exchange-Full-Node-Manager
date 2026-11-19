# 11. Integration API

The API that the exchange server calls, and the events FNM publishes. Users never reach it; the admin panel reaches it only through the exchange's admin API, which adds the staff member's identity and step-up.

## Conventions

- Base path `/v1`, JSON, mTLS, Ed25519 request signatures (headers `X-FNM-Key-Id`, `X-FNM-Timestamp`, `X-FNM-Nonce`, `X-FNM-Signature`).
- `Idempotency-Key` header on every `POST`.
- Amounts are decimal strings of the smallest unit (`"1500000"`), with `asset` and `network`; never floats.
- Errors: `{"error": {"code": "policy_refused", "message": "...", "details": {...}}}`.
- Lists: keyset pagination (`cursor`, `limit`).
- An OpenAPI document is generated and published with each release.

## Routes for the exchange

| Route | Purpose |
| --- | --- |
| `GET /v1/networks` | Networks, their assets, finality, state (`active`, `degraded`, `paused`), minimums |
| `POST /v1/addresses/allocate` | `{owner_ref, family}` → address, network list, signature |
| `GET /v1/addresses/{address}` | Owner reference, status, path, for support |
| `POST /v1/addresses/validate` | `{network, address}` → valid, normalized form, warnings (contract, our own address) |
| `GET /v1/deposits?owner_ref=&status=&cursor=` | Deposits |
| `POST /v1/deposits/{id}/ack` | The exchange credited it |
| `POST /v1/withdrawals` | Request a payment ([08](08-withdrawals.md)) |
| `GET /v1/withdrawals/{id}` | State, attempts, tx ids, fee spent |
| `POST /v1/withdrawals/{id}/cancel` | Possible only before signing |
| `GET /v1/fees/estimate?network=&asset=` | Current network fee, for the exchange to price its withdrawal fee |
| `GET /v1/balances` | Per wallet tier, network, asset: on-chain balance, pending in and out |

## Routes for administration (through the exchange's admin API)

| Route | Purpose |
| --- | --- |
| `GET /v1/admin/nodes`, `POST`, `PATCH /{id}` | Node registry and health |
| `GET /v1/admin/wallets` | Wallets, tiers, balances, caps |
| `GET /v1/admin/sweeps`, `POST /v1/admin/sweeps/run` | Sweeps queue |
| `GET /v1/admin/transfers`, `POST` (request), `POST /{id}/approve` | Treasury moves with two approvals |
| `GET /v1/admin/policies`, `POST` (propose), `POST /{id}/approve` | Policies |
| `POST /v1/admin/networks/{id}/pause`, `/resume` | Kill switches |
| `GET /v1/admin/deposits/held`, `POST /{id}/release` or `/reject` | Held deposits |
| `GET /v1/admin/reconciliation` | Latest results and differences |
| `GET /v1/admin/audit` | Audit log |

Every admin request carries `X-FNM-Actor` (staff id) and the exchange's step-up proof; FNM records it in the audit and enforces "approver differs from requester".

## Events (RabbitMQ, exchange `fnm.events`, topic routing `<network>.<kind>`)

| Event | Meaning |
| --- | --- |
| `DepositDetected`, `DepositConfirmationsChanged`, `DepositFinalized`, `DepositOrphaned`, `DepositHeld` | See [07](07-deposits.md) |
| `WithdrawalAccepted`, `WithdrawalDelayed`, `WithdrawalBroadcast`, `WithdrawalConfirmed`, `WithdrawalFailed` | See [08](08-withdrawals.md) |
| `SweepCompleted`, `FeeSpent` | For the ledger's fee and custody bookings |
| `NetworkStateChanged` | `active` / `degraded` / `paused`, with the reason |
| `ReconciliationMismatch` | A difference above tolerance |

Every event has `event_id` (for deduplication), `occurred_at`, `version`, and FNM's signature. Delivery is at least once, through the transactional outbox.

## Migration of the exchange

1. FNM runs TRON in **shadow mode**: it scans and detects deposits next to the exchange's watcher; results are compared, not acted upon.
2. The exchange's `internal/deposits` allocation calls FNM; the existing addresses are imported (see [06](06-address-management.md)).
3. The exchange switches TRON crediting to `DepositFinalized` and withdrawals to `POST /v1/withdrawals`; `internal/tron` and `cmd/tron-signer` are retired from the exchange.
4. Bitcoin and Ethereum start on FNM directly.

The changes on the exchange side are tracked as issues in the exchange repository, linked from this repository's integration epic.
