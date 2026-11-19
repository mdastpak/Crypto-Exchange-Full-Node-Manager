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
| `POST /v1/addresses/allocate` | `{owner_ref, family}` → address, memo (empty except on memo networks), network list, signature over both |
| `GET /v1/addresses/{address}` | Owner reference, status, path, for support |
| `POST /v1/addresses/validate` | `{network, address, memo}` → valid, normalized form, whether a memo is required, warnings (contract, our own address) |
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

## Takeover of the exchange's custody

The exchange has not gone live, so FNM takes over its custody entirely, with no shadow mode and no import ([#12](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/12), [#65](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/65)):

1. The exchange removes its chain code: `cmd/tron-signer`, `internal/tronsigner`, `internal/tron`, the xpub derivation of `internal/deposits`, and the `custody.providers` configuration with its node URLs and keys.
2. `internal/deposits` keeps the user-facing part (listing a user's addresses and deposits) and gets them from FNM: allocation through `POST /v1/addresses/allocate`, deposits from the events.
3. The ledger credits on `DepositFinalized`, and withdrawals call `POST /v1/withdrawals` after the exchange's own checks; payouts on chain report back through the withdrawal events.
4. The exchange stores and shows the memo with every deposit address and asks for it on withdrawals to memo networks.
5. Every network, TRON included, starts on FNM's own seeds and nodes.

The changes on the exchange side are filed as issues in the exchange repository and linked from the integration epic.
