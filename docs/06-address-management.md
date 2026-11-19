# 06. Address management

## Goals

- Every user has a stable deposit address per network family (one EVM address serves ETH and every ERC-20; one TRON address serves TRX and every TRC-20).
- Allocation is fast (no derivation or chain call on the request path) and **unpredictable**: an address's index does not reveal when the user signed up, how many users there are, or which address the next user gets.
- No address is ever given to two users, and no address the custody does not hold is ever shown.
- FNM can prove, for every address, which xpub and index it came from.

## Generation: the pool

A worker keeps, per network family and deposit xpub, a **pool** of derived but unallocated addresses:

1. It derives addresses at indexes taken from a range in order (`next_index`), stores each with its xpub id, path, and index, and seals the row.
2. A second, independent check re-derives each new address in another process (or the signer's verify endpoint, which derives from the private key) and compares; a mismatch stops the pool and alerts. This catches a wrong xpub or a bug before any user sees the address.
3. The pool is refilled when it falls below a low-water mark (for example 10,000), in batches.

Pool generation is the only place indexes increase; `max_index` per xpub is kept for recovery.

## Allocation: random

`POST /v1/addresses/allocate {owner_ref, family}` (idempotent by `owner_ref` and family):

1. If the owner already has an active address of that family, return it.
2. Otherwise pick one pooled address **uniformly at random** with a CSPRNG (for example `SELECT ... WHERE status='pooled' ORDER BY random_key LIMIT 1 FOR UPDATE SKIP LOCKED`, where `random_key` was drawn from `crypto/rand` at generation), mark it `allocated` to the owner in the same transaction, write the audit event, and return it.
3. `owner_ref` is an opaque reference chosen by the exchange (not the user id), so FNM does not hold personal data.

Because the pool is filled in order but drawn at random, consecutive users get unrelated indexes.

## Lifecycle

```text
pooled -> allocated -> (retired) -> quarantined
```

- **allocated**: watched by the scanner; deposits are attributed to its owner.
- **retired**: the owner closed the account or was given a new address; still watched forever (users reuse old addresses), deposits still attributed, but no longer shown.
- **quarantined**: the address is known to be compromised or poisoned; deposits are detected but held for review.

Addresses are never deleted, and a retired address is never reallocated to someone else.

## Other kinds of addresses

| Kind | How |
| --- | --- |
| Hot, warm wallets | Derived by the signer; registered by `fnmctl wallets register` after a ceremony; marked so the scanner treats transfers from them as internal, not deposits |
| Cold addresses | Registered from the ceremony's descriptor or multisig address; read-only for FNM |
| Change addresses (UTXO) | Internal chain `.../1/i` of the hot wallet account; never shown |
| Destination addresses (withdrawals) | Validated by the adapter; the exchange keeps the users' address book |

## Safety checks

- **Address poisoning**: a deposit of zero value, or of a token not in the registry, from an address resembling one of our hot wallets is ignored and never shown to staff as an address to send to.
- **Checksum and network** are checked on every address that crosses the API in either direction.
- **Display integrity**: the address returned to the exchange carries a signature (FNM's Ed25519 key over network, address, owner_ref) that the exchange stores and the user-facing app can verify, so that a tampered exchange database cannot silently change a user's deposit address.
- **Memo/tag networks** (later): one shared address with a unique memo per user; the memo is allocated the same way.

## Migration of existing TRON addresses

The exchange's existing deposit addresses (derived from the same xpub, one per user) are imported as `allocated` with their indexes, each re-derived and checked; the pool for TRON starts above the highest imported index.
