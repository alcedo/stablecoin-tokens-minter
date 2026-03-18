# Stablecoin Tokens Minter

Foundry-based tooling for deploying a mintable ERC20 and distributing tokens to a batch of recipients on selected EVM chains.

## Configuration

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

The `.env` file controls token metadata, owner/recipient mnemonics, mint amounts, deployer key, and RPC URLs. See `.env.example` for documentation on each variable.

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

## Development

```bash
forge test
forge fmt
```

## Codex Cloud

Configure the Codex Cloud environment to run:

```bash
./codex-cloud-setup.sh
```

The setup script installs the stable Foundry release and runs `forge test` during environment provisioning.

Use Codex Cloud for repo setup, editing, and test runs. Keep real `./mint.sh --broadcast ...` execution local because it depends on runtime secrets such as `PRIVATE_KEY` and chain RPC URLs.
