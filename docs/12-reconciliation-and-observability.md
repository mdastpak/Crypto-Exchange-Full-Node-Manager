# 12. Reconciliation and observability

## Reconciliation

Three checks, each with a metric, a stored result, and an alert above tolerance:

1. **Chain against FNM's state** (every few minutes per network): the on-chain balance of each hot, warm, and cold wallet, and a rotating sample of deposit addresses (all of them daily), against FNM's expected balance (deposits final minus swept, UTXO set, pending outgoing). Differences mean an unknown spend, a missed deposit, or a scanner bug.
2. **FNM against the exchange's books** (hourly, with the exchange's ledger audit, see the exchange's issue #67): the total held by custody per asset (all tiers plus unswept deposits, minus in-flight withdrawals) against the exchange's `custody` account. A shortfall stops withdrawals of that asset.
3. **Signer journal against FNM's attempts** (continuous): every signature the signer reports must match an attempt FNM requested; an unknown signature is a critical alert.

Known timing differences (unconfirmed transactions, deposits not yet acknowledged) are listed explicitly so that only unexplained differences alert.

## Metrics (Prometheus)

| Metric | Labels |
| --- | --- |
| `fnm_node_head_height`, `fnm_node_lag_blocks`, `fnm_node_peers`, `fnm_node_synced`, `fnm_node_rpc_latency_seconds`, `fnm_node_rpc_errors_total` | network, node, method |
| `fnm_scanner_height`, `fnm_scanner_lag_blocks`, `fnm_reorgs_total`, `fnm_reorg_depth` | network |
| `fnm_address_pool_size`, `fnm_addresses_allocated_total` | family |
| `fnm_deposits_total`, `fnm_deposit_finality_seconds`, `fnm_deposits_held` | network, asset, reason |
| `fnm_withdrawals_total`, `fnm_withdrawal_time_to_broadcast_seconds`, `fnm_withdrawal_time_to_final_seconds`, `fnm_withdrawals_stuck` | network, asset, state |
| `fnm_wallet_balance`, `fnm_wallet_cap_ratio` | network, asset, tier |
| `fnm_signer_signatures_total`, `fnm_signer_refusals_total`, `fnm_signer_daily_cap_used_ratio` | family, reason |
| `fnm_reconciliation_difference` | network, asset, check |
| `fnm_outbox_pending`, `fnm_outbox_oldest_seconds` | |

## Alerts

| Severity | Condition |
| --- | --- |
| Page | Reconciliation difference; unknown signature; seal mismatch; reorg deeper than finality; all own nodes of a network unhealthy; hot wallet empty with withdrawals waiting |
| Urgent | One node unhealthy or forked; scanner lag above threshold; stuck withdrawal; nonce gap; disk below 20 percent; signer refusals; caps above 80 percent |
| Info | Pool below low-water mark; refill requested; sweep postponed for gas |

## Logs and traces

`log/slog` JSON with redaction of secrets and owner references; OpenTelemetry traces from the API request through the worker to the signer and the broadcast, with the withdrawal id as an attribute (never the key material).

## Runbooks (`docs/runbooks/`)

Node provisioning, node upgrade and hard fork, resync from snapshot, disk full, scanner stuck, deep reorg, stuck withdrawal (per family), nonce gap, hot wallet empty, reconciliation difference, signer down, suspected key compromise, restore of the FNM database.
