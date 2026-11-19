# 05. Wallets and keys

## Wallet tiers

| Tier | Purpose | Keys held by | Signs | Typical share of funds |
| --- | --- | --- | --- | --- |
| Deposit | One address per user and network, receives deposits | Derived from the **deposit seed**; private keys only in the signer | Sweeps only, to the custody's own addresses | Transient |
| Hot | Pays withdrawals automatically | The **hot seed**, in the signer | Withdrawals within caps; top-ups; sweeps to cold | Small: about one day of withdrawals |
| Warm | Refills the hot wallet | Separate seed, in a signer that requires a **two-person approval** for each transaction; or a 2-of-3 multisig | Only to the hot wallet | Medium |
| Cold | Long-term reserves | Offline, multisig (for example 2-of-3 or 3-of-5) on separate devices and people; never on a networked machine | Only by ceremony | Most |

FNM can send **to** every tier; it can send **from** cold storage only by preparing an unsigned transaction (PSBT for Bitcoin, unsigned transaction for EVM/TRON) that is signed offline and handed back.

Each tier's caps are set per asset: the hot wallet's maximum balance (above it, the excess is swept to warm or cold), its minimum (below it, a refill from warm is requested), and the per-transaction and per-day caps of the signer.

## Seeds and the key hierarchy

Separate seeds limit what one compromise reveals:

| Seed | Derives | Where |
| --- | --- | --- |
| Deposit seed (per family) | Deposit addresses: `m/84'/0'/0'` (BTC), `m/44'/60'/0'` (EVM), `m/44'/195'/0'` (TRON) | Signer of the family; FNM core holds only the account xpub |
| Hot seed (per family) | Hot wallet(s): `.../1'/0/0` and following | Signer of the family |
| Warm seed(s) | Warm wallet | Warm signer, or multisig cosigners |
| Cold keys | Cold multisig | Offline devices |

For TRON, the exchange's existing seed already holds the deposit account (`m/44'/195'/0'`) and the hot wallet (`m/44'/195'/1'/0/0`) under one seed. FNM keeps that seed and those paths for continuity, and new families start with separate seeds. See [14-open-questions.md](14-open-questions.md).

The core zone is configured with account-level xpubs only. A configuration that contains an extended private key is refused at start.

## The signer

One signer deployment per family (`fnm-signer --family utxo|evm|tron`), each on its own host in the signer zone. It:

1. Starts, asks Vault/OpenBao Transit (or an HSM) to decrypt its wrapped seed once with a short-lived token, derives the account keys it needs, and zeroes the seed in memory. The process runs with no swap, no core dumps, and `mlock` where possible.
2. Accepts requests only over mTLS 1.3 from the worker's certificate, each request also signed by the worker's Ed25519 key, with a timestamp and nonce to stop replays.
3. **Rebuilds** every transaction from the plan (inputs, outputs, amounts, fee, nonce), checks it against its own policy, then signs. It never signs raw bytes that it did not build.
4. Enforces its policy, which it loads from a signed policy file (signed by two administrators' keys) and not from the database:
   - destinations allowed per request type: withdrawals to any valid external address; sweeps and top-ups only to the custody's own addresses, which it derives itself; refills only from warm to hot; cold addresses from a fixed list;
   - caps per transaction and per day per asset, and a velocity limit;
   - a maximum fee per transaction.
5. Records every signature in an append-only local journal (and reports it to the core), so that its daily caps survive restarts. One active instance per family; a standby is started only by an operator.

Later options, kept open by this interface: an HSM (PKCS#11) for the hot keys, and MPC/TSS signing to remove the single seed.

## Key ceremonies

Written procedures, each with at least two people and a signed record:

- **Seed generation**: on an offline machine, from a hardware RNG plus `/dev/urandom`; the seed is split with Shamir's secret sharing (for example 3-of-5) onto separate media held by separate people in separate places; the wrapped seed is produced with Vault Transit and copied to the signer host; the xpub and the first addresses are printed and checked by the second person.
- **Cold wallet creation and signing**: multisig descriptors (Bitcoin) or Safe-style multisig (EVM) created offline; spending by PSBT or offline signing with QR or removable media.
- **Rotation**: a new hot seed moves the hot wallet to new addresses (the old wallet is drained); deposit seeds are not rotated unless compromised, because users keep their addresses.
- **Compromise**: stop the signer, freeze the network's withdrawals, move the funds of every address of the compromised seed to cold storage with a new seed, and reallocate deposit addresses to users.

## Recovery

Every address can be re-derived from the seeds and the derivation indexes kept in the database. The database also stores, per seed, the highest index ever derived, so that a recovery from the seeds alone can scan `0..max` without depending on gap limits.
