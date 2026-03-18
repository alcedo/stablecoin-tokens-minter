# Stablecoin Tokens Minter

Foundry-based tooling for deploying a mintable ERC20 and distributing tokens to a batch of recipients on selected EVM chains.

## What You Edit

Update the hardcoded token configuration and recipient list in `script/DeployAndDistribute.s.sol` before running the tool.

The scaffold intentionally starts with:
- `finalOwner = address(0)`
- an empty recipient list

That makes validation fail until you replace the placeholders with real values.

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
export PRIVATE_KEY=0x...
export SEPOLIA_RPC_URL=https://...
./mint.sh --chain sepolia --broadcast
```

Broadcast to mainnet:

```bash
export PRIVATE_KEY=0x...
export ETHEREUM_RPC_URL=https://...
./mint.sh --chain ethereum --broadcast --confirm-mainnet
```

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

The setup script installs the repository's pinned Foundry nightly build, which reports `forge 1.6.0-nightly`, and runs `forge test` during environment provisioning.

Use Codex Cloud for repo setup, editing, and test runs. Keep real `./mint.sh --broadcast ...` execution local because it depends on runtime secrets such as `PRIVATE_KEY` and chain RPC URLs.
