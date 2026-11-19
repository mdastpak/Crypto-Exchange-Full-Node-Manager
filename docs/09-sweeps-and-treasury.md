# 09. Sweeps and treasury

## Sweeps

A sweep moves a deposit address's balance to the hot wallet, or to warm or cold storage when the hot wallet is above its cap.

| Family | How |
| --- | --- |
| UTXO | Not per address: the deposit UTXOs become inputs of the hot wallet directly (the signer holds both keys). They are spent by withdrawals or consolidated in quiet, low-fee periods into fewer UTXOs. |
| EVM | Per address. Native ETH: send balance minus the exact fee. Tokens: the address needs ETH for gas, so a **top-up** from the hot wallet (the exact estimated gas) precedes the token transfer. |
| TRON | Per address, as in the exchange today: top up TRX (or delegate energy, which is cheaper) before a TRC-20 sweep; tokens before TRX. |

### When to sweep

A sweep is planned for an address when its final deposits of an asset exceed a per-asset **sweep threshold**, chosen so that the fee is a small share of the amount (for example under 1 percent). Small deposits accumulate until they pass it. Gas prices above a ceiling postpone non-urgent sweeps. Sweeps run as a queue with limited concurrency per network, so as not to compete with withdrawals for nonces or fees.

Each sweep is a state machine (`planned -> topping_up -> topped_up -> sweeping -> completed | failed`) with its own idempotency key, so a restart continues where it stopped. The sweep's and top-up's transactions are internal transfers and are never seen as deposits.

### Alternative for EVM: forwarder contracts

Instead of EOAs, deposit addresses can be minimal forwarder contracts at CREATE2 addresses that the hot wallet sweeps in batches, without top-ups. It saves fees at scale but adds a contract that must be audited and differs per EVM network. It is an open decision; the first version uses EOAs.

## Treasury rebalancing

Per asset and network, the configuration sets:

| Setting | Effect |
| --- | --- |
| `hot_max` | Above it, the excess goes to cold (or warm), automatically by the signer, to a fixed destination |
| `hot_target` | The balance a refill aims for |
| `hot_min` | Below it, a refill from warm is requested |
| `warm_max` / `warm_min` | The same between warm and cold; moves from cold are always by ceremony |

A refill from warm creates a **transfer request** that needs two staff approvals (through the admin panel), after which the warm signer signs. A move from cold produces an unsigned transaction for the offline ceremony. Moves to cold need no approval, because they only make funds safer, but go only to the registered cold addresses.

## Fee wallets

EVM and TRON top-ups and sweeps spend native coin. The hot wallet keeps a reserve of native coin per network for fees, with its own alert when low; this reserve is accounted as a fee expense to the exchange (`FeeSpent` events) so the ledger can book it.
