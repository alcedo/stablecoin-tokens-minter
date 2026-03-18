# Stablecoin Tokens Minter

Foundry-based tooling for deploying a mintable ERC20 and distributing tokens to a batch of recipients on selected EVM chains.

## Configuration

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

The `.env` file controls token metadata, the final owner address, recipient addresses/amounts, deployer key, and RPC URLs.

### Required mint configuration

Set these fields before running the minter:

- `TOKEN_NAME`
- `TOKEN_SYMBOL`
- `TOKEN_DECIMALS`
- `OWNER_ADDRESS`
- `RECIPIENT_COUNT`
- `RECIPIENT_<n>_ADDRESS`
- `RECIPIENT_<n>_AMOUNT`

Example:

```dotenv
TOKEN_NAME="My USD Stablecoin"
TOKEN_SYMBOL=MYUSD
TOKEN_DECIMALS=6
OWNER_ADDRESS=0x1111111111111111111111111111111111111111
RECIPIENT_COUNT=3
RECIPIENT_1_ADDRESS=0x2222222222222222222222222222222222222222
RECIPIENT_1_AMOUNT=2500000000
RECIPIENT_2_ADDRESS=0x3333333333333333333333333333333333333333
RECIPIENT_2_AMOUNT=1500000000
RECIPIENT_3_ADDRESS=0x4444444444444444444444444444444444444444
RECIPIENT_3_AMOUNT=1000000000
```

Amounts are raw token base units, so a 6-decimal stablecoin uses `1_000_000` units per token.

## Chain Aliases

Chain aliases are defined in `config/chains.sh`.

Included examples:
- `anvil`
- `sepolia`
- `base-sepolia`
- `ethereum`
- `base`

## Usage

Simulation:

```bash
./mint.sh --chain anvil
```

Broadcast to a testnet:

```bash
./mint.sh --chain sepolia --broadcast
```

Broadcast to mainnet:

```bash
./mint.sh --chain ethereum --broadcast --confirm-mainnet
```

Before invoking Foundry, `mint.sh` prints a shell-level preflight summary with the selected chain, token metadata, final owner, recipient count, and total mint amount derived from your `.env`.

## Suggested real mint workflow

1. Populate `.env` with your token metadata, final owner address, and all recipient allocations.
2. Run a simulation first:
   ```bash
   ./mint.sh --chain anvil
   ```
3. Point the chosen chain alias to a real RPC URL and set `PRIVATE_KEY`.
4. Dry-run on a testnet:
   ```bash
   ./mint.sh --chain sepolia
   ./mint.sh --chain sepolia --broadcast
   ```
5. Only after verifying the logs and balances, mint on mainnet with the explicit confirmation flag.

## Development

```bash
forge test
forge fmt
./test/mint.sh.test
```

## Codex Cloud

Configure the Codex Cloud environment to run:

```bash
./codex-cloud-setup.sh
```

The setup script installs the stable Foundry release and runs `forge test` during environment provisioning.

Use Codex Cloud for repo setup, editing, and test runs. Keep real `./mint.sh --broadcast ...` execution local because it depends on runtime secrets such as `PRIVATE_KEY` and chain RPC URLs.
