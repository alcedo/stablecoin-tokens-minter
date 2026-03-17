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
