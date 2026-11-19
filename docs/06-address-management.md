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
- The signature covers the memo as well, so a changed memo is detected like a changed address.

## Memo and tag networks

On TON, XRP, and Stellar, one deposit account per network is shared by every user, and the **memo** says whose deposit it is. This avoids one funded account per user (XRP and Stellar require a reserve per account; TON charges storage) and needs no sweeps from user addresses. The design is in place from the first migration: every address column has a memo column next to it, and every API field that is an address is a destination.

### Allocation

`POST /v1/addresses/allocate {owner_ref, family}` answers `{address, memo}`; on other families `memo` is empty.

1. The memo is drawn **at random** with `crypto/rand`, in the network's format: XRP destination tag in `[1_000_000, 4_294_967_295]`, Stellar memo ID in `[10^9, 2^63)`, TON comment as a fixed-length string of digits (12 characters, so users can type it and no text normalization applies). Low values are skipped because users mistype short tags and other services use them.
2. A unique index on `(network, deposit_account, memo)` makes a collision impossible; on the rare conflict the draw is repeated.
3. **A memo is never reused**, even after its owner leaves: a user who later sends to an old memo must not credit someone else. A retired memo stays attributed to its owner.
4. A memo is per network, not per family, because the formats differ.
5. The `(address, memo)` pair is sealed and signed together.

### Why random and not sequential

Sequential tags reveal the number of users and let an attacker guess other users' tags; a mistyped sequential tag is likely to be another real user's. Random tags in a large space make a typo almost always land on no one, so the deposit is held instead of credited to a stranger.

### Deposits without a valid memo

- **XRP**: the deposit account has `RequireDest` set, so the ledger rejects payments without a tag.
- **Stellar and TON**, and a tag that matches no one on XRP: the deposit is detected and **held** with reason `memo_missing` or `memo_unknown`. Staff can attribute it to a user only through a two-person approval with evidence (the sender proves the transaction), or return it to the sender address, also with two approvals.
- A memo of the wrong type (for example a Stellar `TEXT` memo with a number in it) is held as `memo_invalid`, never parsed loosely.

### Treasury on memo networks

The shared deposit account is swept to the hot wallet above a threshold, keeping its reserve, and the hot wallet to cold storage above its cap, as on the other families ([09](09-sweeps-and-treasury.md)).
