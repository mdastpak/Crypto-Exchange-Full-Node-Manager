# 14. Open questions and decisions

Each question has a recommendation; the owner's answer is recorded here and in its GitHub issue (label `decision`).

| # | Question | Options | Recommendation |
| --- | --- | --- | --- |
| D1 | Does FNM take over the TRON custody that the exchange runs today (`internal/tron`, `internal/deposits`, `cmd/tron-signer`)? | (a) Take over, in shadow mode first; (b) leave TRON in the exchange and add the other networks to FNM | (a): one custody, one set of policies, one reconciliation |
| D2 | TRON keys: keep the existing seed and paths? | (a) Keep the seed, import addresses; (b) new seed, give users new addresses and drain the old ones | (a) for continuity; separate seeds for every new family |
| D3 | EVM deposit addresses | (a) EOAs with gas top-ups; (b) CREATE2 forwarder contracts | (a) first; revisit (b) when EVM deposit volume makes top-ups costly |
| D4 | Where do the nodes and signers run? | Own servers or colocation; domestic data centres; foreign cloud | Needs the owner's input: availability of foreign providers and of third-party node APIs from the exchange's jurisdiction, sanctions exposure, latency, and legal requirements decide this. FNM is designed not to depend on any third-party provider for correctness. |
| D5 | Cold storage technology | Hardware-wallet multisig (offline PSBT and Safe); HSM; an MPC custody provider | Hardware-wallet multisig, 2-of-3 or 3-of-5, with keyholders in separate places |
| D6 | Orchestration of nodes | Docker Compose per host; Kubernetes | Compose per host first; Kubernetes when the number of networks makes it worth it |
| D7 | Shared code with the exchange (row seals, outbox, keys, audit) | Copy and adapt; extract a common Go module | Copy first, extract once both are stable |
| D8 | Witness providers per network | List of providers reachable from the hosting | Depends on D4; at least one independent source per network, or a second own node on another client |
| D9 | Networks after the first set, and their order | BSC, Polygon, Arbitrum, Litecoin, Dogecoin, XRP, TON, Solana | Owner to prioritize by expected volume |
| D10 | License of this repository | Same as the exchange; proprietary | Owner to decide |
| D11 | Language of the documentation | English, like the other two repositories; Persian | English, for consistency with the exchange and the admin panel |
