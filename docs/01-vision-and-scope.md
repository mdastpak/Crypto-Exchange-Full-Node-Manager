# 01. Vision and scope

## The problem

The exchange needs to move real funds on several blockchains. Today the [Crypto Exchange](https://github.com/mdastpak/Crypto-Exchange) does part of this itself, for TRON only: it derives deposit addresses from an xpub (`internal/deposits`), watches TRON blocks through TronGrid (`internal/tron`), and pays withdrawals and sweeps through `cmd/tron-signer` (see its `docs/custody.md`). Adding Bitcoin, Ethereum, and the networks after them in the same way would put every chain's details, every node, and every key path inside the exchange monolith, and would leave the exchange depending on third-party APIs for the truth about its own funds.

## The goal

A separate service, the **Full Node Manager** (FNM), that:

1. **Runs the exchange's own full nodes** for every supported network, and knows at every moment whether each one is synced and trustworthy.
2. **Is the only gateway to the chains.** The exchange never talks to a node or holds a chain-specific detail; it asks FNM for an address, is told about deposits, and asks FNM to pay withdrawals.
3. **Owns the custody**: the key hierarchy, the wallet tiers, the signers, and the policies under which anything is signed.
4. **Is safe by construction**: a compromised exchange server, a lying node, or a careless operator cannot move funds outside the policies.

## Responsibilities

| FNM does | The exchange does |
| --- | --- |
| Run, monitor, and fail over the nodes | Users, sessions, KYC, verification levels |
| Derive, pool, and allocate addresses | Decide which user gets an address, and show it |
| Detect deposits, count confirmations, follow reorgs | Credit the ledger when FNM says a deposit is final; AML on the deposit |
| Estimate fees, build, sign, broadcast, and track transactions | Accept a withdrawal request: limits, second factor, AML, review, locking funds |
| Sweep, top up gas, rebalance hot and cold | The double-entry ledger and its custody account |
| Report on-chain balances per address and wallet | Reconcile those balances with the books |
| Enforce signing policies, caps, and approvals | Show approvals to staff through the admin panel |

The line is: **the exchange decides whether money may move; FNM decides how it moves, and refuses anything its own policies do not allow.** FNM never trusts the exchange blindly: it checks every withdrawal against its own caps, allowlists, and velocity limits.

## Non-goals

- A user-facing API. Users never reach FNM.
- A ledger of user balances. FNM keeps the on-chain state (UTXOs, nonces, address balances, transactions), not who owns what.
- Trading, pricing, or AML rules. The exchange keeps those; FNM only offers address screening hooks.
- Being a general-purpose block explorer or indexer for arbitrary addresses.

## Networks

| Phase | Networks | Family |
| --- | --- | --- |
| First | Bitcoin, Ethereum (ETH, USDT, USDC, WBTC), TRON (TRX, USDT) | UTXO, EVM, TRON |
| Next | BNB Smart Chain, Polygon, Arbitrum, Litecoin, Dogecoin | EVM, UTXO (same adapters, new configuration) |
| Later | Networks with memos or tags (XRP, TON, Stellar), Solana | New adapter families |

The first set matches the networks of the exchange's `config/assets.yaml`.

## Principles

1. **Own nodes first, third parties as witnesses.** Our nodes are the source of truth; an independent provider is used to cross-check large deposits and to detect when our node is behind or forked, never as the only source.
2. **No private key outside a signer.** The API, the scanners, and the database only ever hold public keys and addresses.
3. **Fail closed.** A node that is behind, a signer that cannot be reached, a policy that cannot be read, or a reconciliation difference stops the money paths of that network, not the other networks.
4. **Every movement is idempotent and audited.** Every request carries an idempotency key; every state change writes an append-only audit event in the same transaction.
5. **Least privilege per component.** Each process has its own database role, its own mTLS identity, and only the network routes it needs.
6. **One family, many networks.** A new EVM or UTXO network is configuration, not code.

## Glossary

| Term | Meaning |
| --- | --- |
| Deposit address | An address derived for, and allocated to, one user on one network |
| Hot wallet | The wallet that pays withdrawals automatically, within caps |
| Warm wallet | A wallet that signs only with a staff approval (two people), used to refill the hot wallet |
| Cold storage | Keys kept offline or in an HSM/multisig that FNM can send to but never from |
| Sweep | Moving a deposit address's balance to the hot wallet (or to cold storage) |
| Top-up | Sending native coin to an address so that it can pay the fee of a token transfer |
| Finality | The number of confirmations after which a transaction is treated as final on its network |
| Signer | A process on its own host that holds keys and signs only what its policy allows |
