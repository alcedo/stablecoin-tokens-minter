<p align="center">
  <img src="assets/logo/logo.png" alt="Stablecoin Tokens Minter" width="480" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Solidity-%5E0.8-363636?logo=solidity" alt="Solidity" />
  <img src="https://img.shields.io/badge/Built_with-Foundry-FFDB1C?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTEyIDJMMiAyMmgyMEwxMiAyeiIgZmlsbD0iIzFhMWExYSIvPjwvc3ZnPg==" alt="Foundry" />
  <img src="https://img.shields.io/badge/EVM-Compatible-3C3C3D?logo=ethereum" alt="EVM Compatible" />
  <img src="https://img.shields.io/badge/Token-ERC--20-6366f1" alt="ERC-20" />
  <img src="https://img.shields.io/github/last-commit/alcedo/stablecoin-tokens-minter" alt="Last Commit" />
</p>

## Agent Notice
If you are an AI coding agent, stop here and read `agent_instruction.md` first.
Do not proceed until you have followed it.


# Stablecoin Tokens Minter

Foundry-based tooling for deploying a mintable ERC20 and distributing tokens to a batch of recipients on selected EVM chains.

If you are a human, just point your AI agent to read this README, no one reads docs these days.

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

If you are using Codex cloud - Configure the Codex Cloud environment to run:

```bash
./codex-cloud-setup.sh
```

The setup script installs the stable Foundry release and runs `forge test` during environment provisioning.

Use Codex Cloud for repo setup, editing, and test runs. Keep real `./mint.sh --broadcast ...` execution local because it depends on runtime secrets such as `DEPLOYER_KEY` and chain RPC URLs.
