# 10. Security

## Assets to protect

1. Private keys and seeds (loss = theft of funds).
2. The mapping from addresses to owners (tampering = deposits credited to the wrong user, or users shown an attacker's address).
3. Withdrawal destinations and amounts in flight.
4. The truth about the chain (a lying node = fake deposits or hidden withdrawals).
5. Availability of deposits and withdrawals.

## Threats and controls

| Threat | Controls |
| --- | --- |
| Exchange server compromised, sends withdrawals to the attacker | FNM's own caps, velocity limits, first-destination delay, and approvals; the signer's own caps; hot wallet holds only a day's needs |
| FNM core compromised (API, worker, database) | No private key in the core; signer rebuilds every transaction and checks destinations, caps, and fees under a policy signed by two administrators and not stored in the database; sweeps only to addresses the signer derives itself |
| Signer host compromised | Separate host, minimal software, no inbound except mTLS from the worker; seed only in memory, unwrapped by Vault with a short-lived token; hot wallet small; warm and cold need other keys |
| Database tampered (address mapping, policies) | Row seals (keyed MAC) on addresses, allocations, policies, withdrawals; independent re-derivation of every pooled address; address signatures returned to the exchange |
| Malicious or buggy node | Hash agreement across nodes; witness check on large deposits; finality rules; signer builds transactions itself |
| Replay of API or signer requests | mTLS plus Ed25519 request signatures over method, path, body digest, timestamp, and nonce; nonces remembered for the timestamp window; idempotency keys |
| Insider | Two-person approvals for warm moves, policy changes, and key ceremonies; append-only audit; least-privilege database roles; no single person holds enough Shamir shares |
| Address poisoning, fake tokens | Registry-only assets, ignored zero-value and look-alike transfers, staff UI never offers addresses from the chain |
| Denial of service on nodes | RPC private; P2P limits; two nodes per network; scanning stops safely and catches up |
| Supply chain | Pinned images by digest, verified node releases (signatures and checksums), Go module checksums, Dependabot, reproducible builds of the signer |

## Encryption: external (between services)

- **mTLS 1.3** on every internal call: exchange to API, worker to signers, core to nodes where the client supports TLS (otherwise a WireGuard tunnel or a private network segment).
- A private CA per environment (Vault PKI), short-lived certificates (days), automatic rotation; the client's common name is checked against an allowlist per route.
- **Request signatures** (Ed25519) on top of mTLS from the exchange to FNM and from the worker to the signer, so that a stolen certificate alone is not enough and every request is attributable in the audit log.
- **Events** to the exchange through RabbitMQ over TLS, each event signed by FNM's key so the exchange can verify its origin.
- Webhooks (if used instead of RabbitMQ) are HMAC-SHA256 signed with a timestamp.

## Encryption: internal (at rest and in memory)

- **Seeds**: only as Vault Transit ciphertext on disk; plaintext only in the signer's memory, briefly, then the derived keys only.
- **Data keys**: envelope encryption as in the exchange: data keys wrapped by a KEK in Vault Transit, with rotation; used for row seals and for encrypting sensitive fields (node credentials, provider API keys, owner references if needed).
- **Row seals**: HMAC over the security-relevant columns of addresses, allocations, policies, withdrawals, and attempts; checked on every read on a money path and by a periodic verifier.
- **Database**: TLS connections, encrypted volumes, separate roles for migrations, API, worker, and scanner, each with only the grants it needs.
- **Backups**: encrypted, restore-tested monthly.
- **Logs**: no secrets, keys, raw signed transactions before broadcast, or owner references in clear.

## Approvals

Actions that need **two different staff members** (requested and approved through the admin panel, which signs with each staff member's credentials via the exchange's admin API, step-up authenticated):

- warm-to-hot refills; any movement out of warm;
- changes of signing policies, caps, and the cold address list;
- adding or removing a node, a witness, or a wallet;
- unpausing a network after an integrity alert.

An approval is bound to a digest of exactly what was reviewed; a change after approval invalidates it.

## Audit

Every state change writes an append-only `audit_events` row in the same transaction (actor, action, target, before and after digests, reason, request id). The signer keeps its own journal. Both are shipped to a write-once store.

## Incident response hooks

- Kill switches: per network withdrawals, per network sweeps, global.
- `fnmctl emergency sweep-to-cold <network>` moves the hot wallet's balance to cold storage.
- Alerts (see [12](12-reconciliation-and-observability.md)) page on: reconciliation difference, deep reorg, node fork, seal mismatch, signer refusals, caps reached.
