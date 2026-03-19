# Agent Instruction: One-Shot ERC20 Token Deployment & Minting

## What This Does

This project deploys a new mintable ERC20 token contract and mints tokens to a list of recipient wallets — all in a single atomic transaction on any supported EVM chain. After minting, ownership of the token contract is transferred to a designated final owner address.

The entire flow is: **deploy contract → mint to each recipient → transfer ownership**. One command, one transaction batch.

---

## Prerequisites

Before running anything, the human must have:

1. **Foundry installed** — the `forge` and `cast` CLI tools. Install via `curl -L https://foundry.paradigm.xyz | bash && foundryup`.
2. **A funded deployer wallet** — this account pays gas for the deployment and minting transactions. It needs native ETH (or the chain's native gas token) on the target chain.
3. **The deployer's private key or mnemonic** — used to sign and broadcast transactions.
4. **An RPC endpoint** for the target chain — public defaults are provided, but a private RPC is recommended for reliability.

---

## Parameters the Human Must Provide

All configuration lives in the `.env` file at the project root. Copy `.env.example` to `.env` and fill in these values:

### Token Metadata

| Variable | Description | Example |
|---|---|---|
| `TOKEN_NAME` | Full human-readable name of the token | `"USD Coin"` |
| `TOKEN_SYMBOL` | Ticker symbol (typically 3-6 uppercase chars) | `USDC` |
| `TOKEN_DECIMALS` | Number of decimal places. Use `6` for USDC-style, `18` for ETH-style | `18` |

**Guidance for the human:** Ask them what they want to name their token, what ticker symbol, and how many decimals. Most stablecoins use 6 decimals. Most utility/governance tokens use 18. This cannot be changed after deployment.

### Owner

| Variable | Description | Example |
|---|---|---|
| `OWNER` | BIP-39 mnemonic phrase (12 or 24 words). The address at derivation path `m/44'/60'/0'/0/0` becomes the permanent owner of the token contract after deployment. The owner is the only address that can mint new tokens in the future. | `"word1 word2 word3 ... word12"` |

**Guidance for the human:** This is the wallet that will control the token contract forever. It should be a secure wallet they control — ideally a hardware wallet mnemonic. Ask: "What is the mnemonic phrase for the wallet that should own and control this token contract after deployment?"

### Recipients

The current configuration supports exactly 2 recipients. Each recipient is defined by a mnemonic and an amount:

| Variable | Description | Example |
|---|---|---|
| `RECIPIENT` | BIP-39 mnemonic for recipient 1. Address derived at index 0. | `"word1 word2 ... word12"` |
| `RECIPIENT_AMOUNT` | Amount to mint to recipient 1, in **raw base units** (wei). | `1000000000000000000000` |
| `RECIPIENT2` | BIP-39 mnemonic for recipient 2. Address derived at index 0. | `"word1 word2 ... word12"` |
| `RECIPIENT2_AMOUNT` | Amount to mint to recipient 2, in **raw base units** (wei). | `500000000000000000000` |

**Critical: Amount Calculation**

Amounts are specified in the smallest unit of the token (like wei for ETH). The formula is:

```
raw_amount = human_readable_amount * 10^TOKEN_DECIMALS
```

Examples with `TOKEN_DECIMALS=18`:
- 1,000 tokens → `1000000000000000000000` (1000 * 10^18)
- 500 tokens → `500000000000000000000` (500 * 10^18)
- 1 token → `1000000000000000000` (1 * 10^18)

Examples with `TOKEN_DECIMALS=6`:
- 1,000 tokens → `1000000000` (1000 * 10^6)
- 500 tokens → `500000000` (500 * 10^6)
- 1 token → `1000000` (1 * 10^6)

**Guidance for the human:** Ask: "How many tokens should each recipient receive?" Then compute the raw amount yourself using the decimals they chose. Also ask for the mnemonic phrase of each recipient wallet, OR if they only have an address, they will need to modify the Solidity script (see "Using Raw Addresses Instead of Mnemonics" below).

### Deployer

| Variable | Description | Example |
|---|---|---|
| `DEPLOYER_KEY` | Private key (hex, starting with `0x`) OR a BIP-39 mnemonic of the account that will pay gas and broadcast the transaction. | `0xac0974bec...` or `"word1 word2 ... word12"` |

**Guidance for the human:** Ask: "What is the private key or mnemonic of the wallet that will pay for gas?" This wallet needs enough native gas token (ETH, etc.) on the target chain to cover deployment costs. This wallet does NOT retain any special permissions after deployment — ownership transfers to the `OWNER` address.

If `DEPLOYER_KEY` is unset and the chain is `anvil` (local), it defaults to Anvil's first test account.

### RPC URLs

| Variable | Chain | Default |
|---|---|---|
| `ANVIL_RPC_URL` | Local Anvil | `http://127.0.0.1:8545` |
| `SEPOLIA_RPC_URL` | Ethereum Sepolia testnet | `https://ethereum-sepolia-rpc.publicnode.com` |
| `BASE_SEPOLIA_RPC_URL` | Base Sepolia testnet | `https://sepolia.base.org` |
| `ETHEREUM_RPC_URL` | Ethereum mainnet | `https://cloudflare-eth.com` |
| `BASE_RPC_URL` | Base mainnet | `https://mainnet.base.org` |

**Guidance for the human:** Ask which chain they want to deploy on. If they have a private/premium RPC URL, use that for better reliability. The defaults work but may be rate-limited.

---

## Supported Chains

| Alias | Chain ID | Network | Mainnet? |
|---|---|---|---|
| `anvil` | 31337 | Local development | No |
| `sepolia` | 11155111 | Ethereum Sepolia testnet | No |
| `base-sepolia` | 84532 | Base Sepolia testnet | No |
| `ethereum` | 1 | Ethereum mainnet | Yes |
| `base` | 8453 | Base mainnet | Yes |

---

## Execution Commands

### Step 1: Simulate (Dry Run)

Always simulate first. This validates all parameters without spending gas:

```bash
./mint.sh --chain <alias>
```

Example:
```bash
./mint.sh --chain sepolia
```

The script prints a preflight summary showing: chain, token metadata, final owner address, recipient count, and total mint amount. Verify everything looks correct.

### Step 2: Broadcast (Live Deployment)

For testnets:
```bash
./mint.sh --chain sepolia --broadcast
```

For mainnets (requires explicit confirmation flag as a safety measure):
```bash
./mint.sh --chain ethereum --broadcast --confirm-mainnet
```

### What Happens On Broadcast

1. The `MintableERC20` contract is deployed with the specified name, symbol, and decimals. The deployer is set as temporary owner.
2. `token.mint(recipient, amount)` is called for each recipient.
3. `token.transferOwnership(finalOwner)` transfers control to the `OWNER`-derived address.
4. The deployed token contract address is printed to the console.

All of this happens inside a single `forge script` broadcast session.

---

## Verifying Success

After broadcast, the script logs the deployed token contract address. Verify on the chain's block explorer:

| Chain | Explorer |
|---|---|
| Sepolia | `https://sepolia.etherscan.io/address/<TOKEN_ADDRESS>` |
| Base Sepolia | `https://sepolia.basescan.org/address/<TOKEN_ADDRESS>` |
| Ethereum | `https://etherscan.io/address/<TOKEN_ADDRESS>` |
| Base | `https://basescan.org/address/<TOKEN_ADDRESS>` |

You can also verify balances with `cast`:

```bash
cast call <TOKEN_ADDRESS> "balanceOf(address)(uint256)" <RECIPIENT_ADDRESS> --rpc-url <RPC_URL>
```

And verify ownership:

```bash
cast call <TOKEN_ADDRESS> "owner()(address)" --rpc-url <RPC_URL>
```

---

## Using Raw Addresses Instead of Mnemonics

The current `.env` configuration uses BIP-39 mnemonics for the owner and recipients, deriving addresses at index 0 (`m/44'/60'/0'/0/0`). If the human only has raw Ethereum addresses (e.g., `0xABC...`), the Solidity script needs modification.

To convert a mnemonic to its address for verification:
```bash
cast wallet address --mnemonic "word1 word2 ... word12"
```

If the human wants to use raw addresses directly, modify `script/DeployAndDistribute.s.sol`:

In `_tokenConfig()`, replace the mnemonic derivation:
```solidity
// Instead of:
string memory ownerMnemonic = vm.envString("OWNER");
uint256 ownerKey = vm.deriveKey(ownerMnemonic, 0);
config.finalOwner = vm.addr(ownerKey);

// Use:
config.finalOwner = vm.envAddress("OWNER_ADDRESS");
```

In `_recipients()`, replace similarly:
```solidity
// Instead of:
string memory r1Mnemonic = vm.envString("RECIPIENT");
uint256 r1Key = vm.deriveKey(r1Mnemonic, 0);
recipients[0] = Recipient({to: vm.addr(r1Key), amount: r1Amount});

// Use:
recipients[0] = Recipient({to: vm.envAddress("RECIPIENT_ADDRESS"), amount: r1Amount});
```

Then update `.env` to use `OWNER_ADDRESS=0x...`, `RECIPIENT_ADDRESS=0x...`, etc.

---

## Adding More Recipients

The current script hardcodes 2 recipients. To add more, modify `_recipients()` in `script/DeployAndDistribute.s.sol`:

1. Increase the array size: `recipients = new Recipient[](N);`
2. Add new entries: `recipients[2] = Recipient({to: ..., amount: ...});`
3. Add corresponding env vars to `.env`: `RECIPIENT3`, `RECIPIENT3_AMOUNT`, etc.
4. Update `mint.sh` validation if desired (the `load_script_preflight` function).

---

## Error Conditions

The Solidity script validates all inputs before deploying. These will cause a revert:

| Error | Cause |
|---|---|
| `EmptyTokenName` | `TOKEN_NAME` is empty |
| `EmptyTokenSymbol` | `TOKEN_SYMBOL` is empty |
| `ZeroFinalOwner` | Owner mnemonic derived to the zero address |
| `EmptyRecipients` | No recipients defined |
| `ZeroRecipientAddress(index)` | A recipient mnemonic derived to the zero address |
| `ZeroRecipientAmount(index)` | A recipient amount is 0 |
| `DuplicateRecipient(address)` | Two recipients resolved to the same address |

The shell script (`mint.sh`) also validates that all required env vars are set before invoking Foundry.

---

## Security Notes

- **Never commit `.env` to version control.** It is already in `.gitignore`.
- **`DEPLOYER_KEY` contains a private key or mnemonic.** Treat it as a secret. Prefer setting it as an environment variable (`export DEPLOYER_KEY=0x...`) rather than writing it to `.env`.
- **The `OWNER` mnemonic controls the token contract permanently.** Whoever holds this mnemonic can mint unlimited tokens. Use a secure, backed-up wallet.
- **Recipient mnemonics are sensitive.** If you're minting to wallets you don't control, ask for their addresses instead and use the raw address modification described above.
- **Simulate before broadcasting.** Always run without `--broadcast` first to catch configuration errors without spending gas.
- **Mainnet requires `--confirm-mainnet`.** This is a deliberate safety gate to prevent accidental mainnet deployments.

---

## Quick Reference: Minimal Steps for an Agent

1. Ask the human for: token name, symbol, decimals, owner wallet (mnemonic or address), recipient wallets + amounts, deployer private key, and target chain.
2. Compute raw amounts: `human_amount * 10^decimals`.
3. Write the `.env` file with all values.
4. Run `./mint.sh --chain <alias>` to simulate and verify the preflight output.
5. Run `./mint.sh --chain <alias> --broadcast` (add `--confirm-mainnet` for mainnet).
6. Capture the deployed token address from the output.
7. Verify balances on-chain using `cast call` or the block explorer.
