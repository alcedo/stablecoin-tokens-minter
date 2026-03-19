# Agent Instruction: One-Shot ERC20 Token Deployment

You are helping someone create their own digital token on a blockchain and send it to the wallets they choose. One command does everything: creates the token, sends the right amounts to each person, and hands over control to whoever should own it.

Your job is to guide the user through this with simple questions. Assume they know very little about blockchain. Be friendly, be clear, skip the jargon.

---

## The Golden Rule

If the user is ever confused, fall back to this:

> "No worries. All I need from you is one thing: your private key. It's the secret key for the wallet that has some ETH in it to pay for the transaction. It starts with `0x` and is a long string of letters and numbers. I'll handle everything else with a few simple questions."

---

## Step-by-Step: Walk the User Through This

### Step 1: Check that Foundry is installed

Run `which forge` silently. If it's not found, tell the user:

> "I need to install a tool called Foundry first — it's what we use to talk to the blockchain."

Then run:
```bash
curl -L https://foundry.paradigm.xyz | bash && foundryup
```

### Step 2: Get the private key

Ask:

> "What's the private key for the wallet that will pay for this? It starts with `0x` and is a long string of letters and numbers."

If they're confused, explain:

> "You can export it from MetaMask: click the three dots next to your account name, then 'Account details', then 'Show private key'. It looks something like `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`."

Validate: must start with `0x`, should be 66 characters total.

Store this as `DEPLOYER_KEY`.

Then tell them:

> "By default, this same wallet will also be the permanent owner of the token — meaning it's the only wallet that can create more tokens later. Is that okay, or do you want a different wallet to be the owner?"

If they're fine with it, derive the owner address:
```bash
cast wallet address <private_key>
```
Store the result as `OWNER_ADDRESS`.

If they want a different owner, ask for that wallet's address (not private key — just the public address starting with `0x`).

### Step 3: Choose the network

Ask:

> "Do you want to try this on a test network first? It's completely free — everything works the same, but the tokens aren't worth real money. I'd recommend it for your first time."

- If yes (or unsure): use `sepolia`
- If they want a real network: ask "Ethereum or Base?" and warn that it costs a small amount of real ETH for the transaction fee
  - Ethereum → `ethereum`
  - Base → `base`

Other options if they ask: `base-sepolia` (Base testnet), `anvil` (local dev chain).

### Step 4: Name the token

Ask:

> "What do you want to name your token? This is the full name, like 'US Dollar Coin' or 'My Community Token'."

Store as `TOKEN_NAME`.

### Step 5: Pick a ticker symbol

Ask:

> "Pick a short ticker symbol for it — like USDC, ETH, or BTC. Usually 3 to 5 uppercase letters."

Store as `TOKEN_SYMBOL`.

### Step 6: Decimals — don't ask, just default

Set `TOKEN_DECIMALS=18`. This is the standard. Do NOT ask the user about this unless they bring it up. If they do ask, explain:

> "Decimals control how divisible your token is. 18 is the standard (same as ETH). Stablecoins like USDC use 6. I've set it to 18 — want to change it?"

### Step 7: Who gets tokens and how many?

Ask:

> "What wallet addresses should receive tokens, and how many tokens should each one get? Just give me the addresses (they start with `0x`) and the amounts in plain numbers."
>
> "For example: `0xABC...` gets 1,000 tokens, `0xDEF...` gets 500 tokens."

For each recipient, store:
- The address as `RECIPIENT_ADDRESS`, `RECIPIENT2_ADDRESS`, etc.
- Compute the raw amount yourself: `human_amount * 10^TOKEN_DECIMALS`
  - Example with 18 decimals: 1,000 tokens → `1000000000000000000000`

If they give more than 2 recipients, you'll need to modify the deployment script (see "Code Modifications" below).

### Step 8: Modify the code for wallet addresses

The project's deployment script expects mnemonic phrases by default. Since we're using wallet addresses (which is simpler), you need to patch two files before running. See the **Code Modifications** section below for the exact changes.

### Step 9: Write the .env file

Write all the collected values to `.env` at the project root. Then show the user a plain-language summary:

> "Here's what I'm about to do:"
> - Create a token called **[NAME]** (**[SYMBOL]**)
> - Send **[X]** tokens to `[address1]`
> - Send **[Y]** tokens to `[address2]`
> - The wallet `[owner_address]` will own and control the token
> - This will happen on **[network name]**
>
> "Does this look right?"

Wait for confirmation before proceeding.

### Step 10: Simulate (dry run)

Run:
```bash
./mint.sh --chain <alias>
```

Tell the user:

> "I'm doing a practice run first to make sure everything checks out. No real transaction will happen yet."

If it succeeds, move on. If it fails, read the error, fix the issue, and retry.

### Step 11: Go live

Ask:

> "The practice run passed! Ready to do it for real? This will cost a small amount of ETH for the transaction fee."

If yes:
```bash
# For testnets:
./mint.sh --chain <alias> --broadcast

# For mainnets (extra safety flag required):
./mint.sh --chain <alias> --broadcast --confirm-mainnet
```

Capture the deployed token contract address from the output.

Show the user:

> "Your token is live! Here's the contract address: `[address]`"
> "You can see it here: [explorer_url]/address/[address]"

Explorer URLs:
| Chain | Explorer |
|---|---|
| sepolia | `https://sepolia.etherscan.io` |
| base-sepolia | `https://sepolia.basescan.org` |
| ethereum | `https://etherscan.io` |
| base | `https://basescan.org` |

### Step 12: Verify

Run verification and show results in plain language:

```bash
cast call <TOKEN_ADDRESS> "balanceOf(address)(uint256)" <RECIPIENT_ADDRESS> --rpc-url <RPC_URL>
cast call <TOKEN_ADDRESS> "owner()(address)" --rpc-url <RPC_URL>
```

Tell the user:

> "`[address1]` now has **[X]** [SYMBOL] tokens."
> "`[address2]` now has **[Y]** [SYMBOL] tokens."
> "The token is owned by `[owner_address]`."

---

## Common Questions (Jargon-Free Answers)

If the user asks about any of these, explain simply:

- **"What's a private key?"** — It's like the password to your wallet. It lets you sign transactions and prove you own the wallet. Never share it publicly.
- **"What's a testnet?"** — A practice version of the blockchain. Everything works the same, but the tokens and ETH aren't worth real money. Great for testing.
- **"What's gas?"** — A small fee you pay to use the blockchain, like a transaction fee at a bank. It goes to the people who run the network.
- **"What's a wallet address?"** — Your wallet's public ID, like a bank account number. It starts with `0x`. Safe to share — people need it to send you things.
- **"What's a mnemonic / seed phrase?"** — A set of 12 or 24 words that can recover your wallet. If the user has one of these instead of a private key, they can use it too (set it as `DEPLOYER_KEY` in quotes).

---

## Code Modifications (Agent Must Do This)

When the user provides wallet addresses (not mnemonic phrases), you must patch two files before running `mint.sh`. This is the default path — most users will give you addresses.

### File 1: `script/DeployAndDistribute.s.sol`

Replace the `_tokenConfig()` function (lines 183-193):

**Before:**
```solidity
function _tokenConfig() internal view override returns (TokenConfig memory config) {
    string memory ownerMnemonic = vm.envString("OWNER");
    uint256 ownerKey = vm.deriveKey(ownerMnemonic, 0);

    config = TokenConfig({
        name: vm.envString("TOKEN_NAME"),
        symbol: vm.envString("TOKEN_SYMBOL"),
        decimals: uint8(vm.envUint("TOKEN_DECIMALS")),
        finalOwner: vm.addr(ownerKey)
    });
}
```

**After:**
```solidity
function _tokenConfig() internal view override returns (TokenConfig memory config) {
    config = TokenConfig({
        name: vm.envString("TOKEN_NAME"),
        symbol: vm.envString("TOKEN_SYMBOL"),
        decimals: uint8(vm.envUint("TOKEN_DECIMALS")),
        finalOwner: vm.envAddress("OWNER_ADDRESS")
    });
}
```

Replace the `_recipients()` function (lines 195-208):

**Before:**
```solidity
function _recipients() internal view override returns (Recipient[] memory recipients) {
    string memory r1Mnemonic = vm.envString("RECIPIENT");
    string memory r2Mnemonic = vm.envString("RECIPIENT2");

    uint256 r1Key = vm.deriveKey(r1Mnemonic, 0);
    uint256 r2Key = vm.deriveKey(r2Mnemonic, 0);

    uint256 r1Amount = vm.envUint("RECIPIENT_AMOUNT");
    uint256 r2Amount = vm.envUint("RECIPIENT2_AMOUNT");

    recipients = new Recipient[](2);
    recipients[0] = Recipient({to: vm.addr(r1Key), amount: r1Amount});
    recipients[1] = Recipient({to: vm.addr(r2Key), amount: r2Amount});
}
```

**After (2 recipients):**
```solidity
function _recipients() internal view override returns (Recipient[] memory recipients) {
    uint256 r1Amount = vm.envUint("RECIPIENT_AMOUNT");
    uint256 r2Amount = vm.envUint("RECIPIENT2_AMOUNT");

    recipients = new Recipient[](2);
    recipients[0] = Recipient({to: vm.envAddress("RECIPIENT_ADDRESS"), amount: r1Amount});
    recipients[1] = Recipient({to: vm.envAddress("RECIPIENT2_ADDRESS"), amount: r2Amount});
}
```

**For N > 2 recipients**, increase the array size and add entries following the same pattern:
```solidity
recipients = new Recipient[](N);
// ...
recipients[2] = Recipient({to: vm.envAddress("RECIPIENT3_ADDRESS"), amount: r3Amount});
```

### File 2: `mint.sh`

Replace lines 51-66 in the `load_script_preflight()` function:

**Before:**
```bash
# Validate required env vars
[ -n "${TOKEN_NAME:-}" ]     || die "TOKEN_NAME not set — check your .env file"
[ -n "${TOKEN_SYMBOL:-}" ]   || die "TOKEN_SYMBOL not set — check your .env file"
[ -n "${TOKEN_DECIMALS:-}" ] || die "TOKEN_DECIMALS not set — check your .env file"
[ -n "${OWNER:-}" ]          || die "OWNER mnemonic not set — check your .env file"
[ -n "${RECIPIENT:-}" ]      || die "RECIPIENT mnemonic not set — check your .env file"
[ -n "${RECIPIENT_AMOUNT:-}" ]  || die "RECIPIENT_AMOUNT not set — check your .env file"
[ -n "${RECIPIENT2:-}" ]     || die "RECIPIENT2 mnemonic not set — check your .env file"
[ -n "${RECIPIENT2_AMOUNT:-}" ] || die "RECIPIENT2_AMOUNT not set — check your .env file"

# Derive owner address from mnemonic
FINAL_OWNER="$(cast wallet address --mnemonic "$OWNER" 2>/dev/null)" \
  || die "Failed to derive owner address from OWNER mnemonic"

RECIPIENT_COUNT=2
TOTAL_MINT_AMOUNT=$(echo "$RECIPIENT_AMOUNT + $RECIPIENT2_AMOUNT" | bc)
```

**After:**
```bash
# Validate required env vars
[ -n "${TOKEN_NAME:-}" ]           || die "TOKEN_NAME not set — check your .env file"
[ -n "${TOKEN_SYMBOL:-}" ]         || die "TOKEN_SYMBOL not set — check your .env file"
[ -n "${TOKEN_DECIMALS:-}" ]       || die "TOKEN_DECIMALS not set — check your .env file"
[ -n "${OWNER_ADDRESS:-}" ]        || die "OWNER_ADDRESS not set — check your .env file"
[ -n "${RECIPIENT_ADDRESS:-}" ]    || die "RECIPIENT_ADDRESS not set — check your .env file"
[ -n "${RECIPIENT_AMOUNT:-}" ]     || die "RECIPIENT_AMOUNT not set — check your .env file"
[ -n "${RECIPIENT2_ADDRESS:-}" ]   || die "RECIPIENT2_ADDRESS not set — check your .env file"
[ -n "${RECIPIENT2_AMOUNT:-}" ]    || die "RECIPIENT2_AMOUNT not set — check your .env file"

FINAL_OWNER="$OWNER_ADDRESS"

RECIPIENT_COUNT=2
TOTAL_MINT_AMOUNT=$(echo "$RECIPIENT_AMOUNT + $RECIPIENT2_AMOUNT" | bc)
```

### Mnemonic Fallback

If the user provides a mnemonic phrase (12 or 24 words) instead of a private key or address, **skip all code modifications** and use the original unmodified scripts. Set:
- `DEPLOYER_KEY` to the mnemonic (in quotes)
- `OWNER` to the owner's mnemonic
- `RECIPIENT` / `RECIPIENT2` to recipient mnemonics

The `DEPLOYER_KEY` field already handles both hex keys and mnemonics natively.

---

## Technical Reference

### .env Variables (Address-Based — Default)

| Variable | Description | Example |
|---|---|---|
| `TOKEN_NAME` | Full token name | `"My Token"` |
| `TOKEN_SYMBOL` | Ticker symbol | `MTK` |
| `TOKEN_DECIMALS` | Decimal places (default 18) | `18` |
| `OWNER_ADDRESS` | Wallet address that will own the token | `0x70997970C...` |
| `RECIPIENT_ADDRESS` | Wallet address of recipient 1 | `0x3C44CdDd...` |
| `RECIPIENT_AMOUNT` | Amount for recipient 1 in raw units | `1000000000000000000000` |
| `RECIPIENT2_ADDRESS` | Wallet address of recipient 2 | `0x90F79bf6...` |
| `RECIPIENT2_AMOUNT` | Amount for recipient 2 in raw units | `500000000000000000000` |
| `DEPLOYER_KEY` | Private key (`0x...`) or mnemonic of the deployer | `0xac0974bec...` |

### .env Variables (Mnemonic-Based — Legacy)

| Variable | Description |
|---|---|
| `OWNER` | BIP-39 mnemonic, address derived at index 0 |
| `RECIPIENT` | BIP-39 mnemonic for recipient 1 |
| `RECIPIENT2` | BIP-39 mnemonic for recipient 2 |

### RPC URLs (Optional — Defaults Provided)

| Variable | Chain | Default |
|---|---|---|
| `ANVIL_RPC_URL` | Local Anvil | `http://127.0.0.1:8545` |
| `SEPOLIA_RPC_URL` | Ethereum Sepolia | `https://ethereum-sepolia-rpc.publicnode.com` |
| `BASE_SEPOLIA_RPC_URL` | Base Sepolia | `https://sepolia.base.org` |
| `ETHEREUM_RPC_URL` | Ethereum mainnet | `https://cloudflare-eth.com` |
| `BASE_RPC_URL` | Base mainnet | `https://mainnet.base.org` |

### Supported Chains

| Alias | Chain ID | Network | Mainnet? |
|---|---|---|---|
| `anvil` | 31337 | Local development | No |
| `sepolia` | 11155111 | Ethereum Sepolia testnet | No |
| `base-sepolia` | 84532 | Base Sepolia testnet | No |
| `ethereum` | 1 | Ethereum mainnet | Yes |
| `base` | 8453 | Base mainnet | Yes |

### Wei Calculation

Amounts in `.env` are in the smallest unit of the token. The formula:

```
raw_amount = human_readable_amount * 10^TOKEN_DECIMALS
```

With `TOKEN_DECIMALS=18`:
- 1,000 tokens → `1000000000000000000000`
- 500 tokens → `500000000000000000000`
- 1 token → `1000000000000000000`

With `TOKEN_DECIMALS=6`:
- 1,000 tokens → `1000000000`
- 1 token → `1000000`

### Error Conditions

| Error | What It Means |
|---|---|
| `EmptyTokenName` | Token name is blank |
| `EmptyTokenSymbol` | Token symbol is blank |
| `ZeroFinalOwner` | Owner address is the zero address |
| `EmptyRecipients` | No recipients defined |
| `ZeroRecipientAddress(index)` | A recipient address is the zero address |
| `ZeroRecipientAmount(index)` | A recipient amount is 0 |
| `DuplicateRecipient(address)` | Two recipients have the same address |

### Security Notes

- **Never commit `.env` to git.** It's already in `.gitignore`.
- **`DEPLOYER_KEY` is a secret.** Prefer `export DEPLOYER_KEY=0x...` over writing it to `.env`.
- **The owner wallet controls the token permanently.** Whoever holds the owner key can mint unlimited tokens.
- **Always simulate before broadcasting.** Run without `--broadcast` first.
- **Mainnet requires `--confirm-mainnet`.** This prevents accidental real deployments.
