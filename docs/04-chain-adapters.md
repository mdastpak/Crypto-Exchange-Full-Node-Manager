# 04. Chain adapters

Every network is reached through one Go interface, implemented once per family. The rest of FNM never imports a chain library.

## The interface (sketch)

```go
type Adapter interface {
    Network() NetworkID

    // Addresses (public keys only).
    DeriveAddress(xpub ExtendedPublicKey, path DerivationPath) (Address, error)
    ValidateDestination(addr string, memo *string) (Destination, error) // checksum, network, type, memo format; rejects own contracts where needed
    MemoRule() MemoRule              // none, optional, or required; its format (uint32 tag, uint64 id, text up to N bytes)

    // Reading.
    Head(ctx context.Context) (BlockRef, error)
    Block(ctx context.Context, height uint64) (Block, error)          // normalized transfers to and from watched addresses
    Transaction(ctx context.Context, id TxID) (TxStatus, error)
    Balance(ctx context.Context, addr Address, asset AssetID) (Amount, error)

    // Writing (no keys).
    EstimateFee(ctx context.Context, req FeeRequest) (FeeQuote, error)
    BuildUnsigned(ctx context.Context, plan TxPlan) (UnsignedTx, error)   // fully specified: inputs/nonce, outputs, fee
    Broadcast(ctx context.Context, signed SignedTx) (TxID, error)

    // Rules.
    Finality() FinalityRule          // confirmations, or the network's finalized tag
    ReorgDepth() uint64              // how far back to keep block hashes
}
```

The signer has its own, smaller interface: it receives a `TxPlan`, **rebuilds and checks the transaction itself** (so a compromised worker or node cannot make it sign something else), signs, and returns the signed bytes. This mirrors what `cmd/tron-signer` does in the exchange today.

All amounts are integers in the asset's smallest unit (`big.Int`), never floats; conversion to decimals happens only at the edge, with the decimals from the asset registry.

A `Destination` is `{Address, Memo}` with `Memo` empty on networks without memos. Every normalized `Transfer` carries the memo it was sent with, and every `TxPlan` output carries the memo to send. The UTXO, EVM, and TRON families always report an empty memo (TRON's free-form `data` field is never used to identify users), so the rest of FNM handles every family the same way.

## Families

### UTXO (Bitcoin, later Litecoin, Dogecoin)

- Addresses: native SegWit P2WPKH (BIP84, `m/84'/0'/0'/0/i`). Taproot (BIP86) can be added for change and cold outputs later. Withdrawals accept every standard type (P2PKH, P2SH, P2WPKH, P2WSH, P2TR).
- Scanning: each block's outputs are matched against the set of watched scripts held in memory (refreshed on allocation); spends of our UTXOs are matched by outpoint.
- FNM keeps its own UTXO set per wallet, with states `unconfirmed`, `confirmed`, `reserved` (planned for a transaction), `spent`.
- Fees: `estimatesmartfee` from our node, bounded by a configured floor and ceiling, compared with a provider's estimate; RBF enabled on every transaction; CPFP for stuck incoming sweeps.
- Finality: 3 confirmations by default for crediting (configurable per amount: larger amounts need more), 6 for our own UTXOs to be spendable by withdrawals.

### EVM (Ethereum, later BSC, Polygon, Arbitrum)

- Addresses: BIP44 `m/44'/60'/0'/0/i`, EIP-55 checksums enforced on input when mixed-case.
- Scanning: native ETH by block transactions plus `debug_traceBlockByNumber` for internal transfers; tokens by `eth_getLogs` for the `Transfer` topic of the configured contracts, filtered locally by watched address. Only tokens in the asset registry are ever credited.
- Finality: Ethereum's `finalized` block tag (about two epochs); for EVM networks without such a tag, a confirmation count.
- Nonces: FNM is the only sender of its hot wallets; it allocates nonces from its own table under a row lock, never from `eth_getTransactionCount(pending)` alone, and detects gaps.
- Fees: EIP-1559 (`maxFeePerGas`, `maxPriorityFeePerGas`) from `eth_feeHistory`, with ceilings; replacement by the same nonce with at least +10 percent fees for stuck transactions.
- Token decimals and contract addresses come from the registry, never from the chain at run time.

### TRON (TRX, TRC-20)

- Addresses: `m/44'/195'/0'/0/i` from FNM's own TRON deposit seed, Base58Check with the `0x41` prefix. The exchange's earlier TRON seed is not used: it never went live ([#65](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/65)).
- Scanning: blocks by `getblockbynum`, TRC-20 transfers from the transaction info logs; only the registry's contracts.
- Resources: bandwidth and energy. Token transfers need energy; FNM either burns TRX within `fee_limit`, or (later) freezes TRX for energy on the hot wallet, or delegates energy to deposit addresses before sweeps, which is cheaper than sending TRX.
- Finality: 19 confirmations (solidified blocks), as in the exchange today.
- Transactions expire about 10 minutes after their reference block; an expired, unseen transaction is rebuilt and signed again under the same request.

### Memo family (TON, XRP, Stellar)

One shared deposit account per network receives every user's deposits; the memo identifies the user ([06](06-address-management.md#memo-and-tag-networks)).

| | XRP Ledger | Stellar | TON |
| --- | --- | --- | --- |
| Memo | Destination tag, uint32 | Memo of type `ID` (uint64) | Text comment |
| Deposit account flags | `RequireDest` set, so the ledger itself rejects payments without a tag; `DisallowXRP` not set | None available; missing memos are held | None available; missing comments are held |
| Trusted amount | `meta.delivered_amount` only, never `Amount`: **partial payments** can deliver far less than `Amount` | The operation's amount; path payments by their received amount | The amount of the incoming internal message; jettons by the transfer notification from **our own jetton wallet** for the registered jetton master, never a notification from another contract |
| Tokens | Issued currencies by issuer and code, from the registry | Assets by issuer and code; trustlines established by ceremony | Jettons by master contract, from the registry |
| Finality | Validated ledger | Closed ledger | Masterchain-confirmed block |
| Reserves | Base and owner reserves kept on the account | Minimum balance per subentry | Storage fees; balance kept above a floor |
| Derivation | `m/44'/144'/0'/0/i` (secp256k1) | SLIP-10 ed25519 `m/44'/148'/i'` | ed25519, wallet contract v4/v5 address |
| Multisig (cold) | `SignerList` with a quorum | Account signers with thresholds | Multisig wallet contract |

Failed and bounced transfers are never deposits; a TON transfer to a bounceable address that bounced is recorded with the bounce.

## Test strategy

- Unit tests with recorded node responses for each family.
- Integration tests against regtest (Bitcoin), a dev chain (Geth `--dev` or Anvil), and a TRON private network or Nile, run in CI with Docker.
- Property tests for UTXO selection and nonce allocation.
- A reorg test per family: produce a fork on the regtest or dev chain and check that deposits are rolled back and re-detected.
