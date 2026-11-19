# 14. Decisions

The design decisions, each recorded in its GitHub issue (label `type: decision`). D1, D2, and D5 were made by the owner; the rest were delegated, and were made for the strongest security and availability, accepting more cost or work where needed.

| # | Question | Decision | Why |
| --- | --- | --- | --- |
| [D1](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/12) | Does FNM take over the TRON custody of the exchange? | **Yes, entirely**, with no shadow mode: the exchange removes its chain code | The exchange has not gone live; one custody, one set of policies, one reconciliation |
| [D2](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/65) | Keep the exchange's TRON seed and addresses? | **No.** New seeds from FNM's ceremony, nothing imported | Nothing live to preserve; separate deposit and hot seeds |
| [D3](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/66) | EVM deposit addresses | **EOAs** with gas top-ups | No custody code on chain that could fail for every address at once |
| [D4](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/67) | Hosting | **Dedicated bare metal in two independent data centres**; signers on their own servers in a locked rack | No shared hypervisor; no single operator or site can stop a network; see [03](03-full-nodes.md#hosting) |
| [D5](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/68) | Cold storage | **Multisig with hardware wallets**, 3-of-5, two vendors, five keyholders in separate places | Owner's choice; quorum and vendors chosen so that two lost keys or one vendor's flaw cannot lose or move funds; see [05](05-wallets-and-keys.md#cold-storage) |
| [D6](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/70) | Orchestration | **Docker Compose per dedicated host** | Smallest attack surface; one node per host already isolates |
| [D7](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/70) | Shared code with the exchange | **Copy and adapt**; no build-time dependency on the exchange | A change or a compromised dependency in the exchange cannot reach the custody |
| [D8](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/67) | Witnesses | **A second own node on a different client** for every network; external providers only as extra witnesses where reachable and lawful | Correctness never depends on a third party; one client's bug is caught by the other |
| [D9](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/69) | Networks after the first set | Second: BSC, Polygon, Arbitrum, Litecoin, Dogecoin. Third: TON, XRP, Stellar (memo family). Fourth: Solana | Configuration-only networks first; the memo family is designed in from the start |
| [D10](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/70) | License | **MIT**, as the exchange | Consistency; the security of the custody never relies on its code being secret |
| [D11](https://github.com/mdastpak/Crypto-Exchange-Full-Node-Manager/issues/70) | Language of the documentation | **English**, as the exchange and the admin panel | One language across the three repositories and their reviews |
