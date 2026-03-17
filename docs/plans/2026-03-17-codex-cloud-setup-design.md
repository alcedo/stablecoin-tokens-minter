# Codex Cloud Setup Script Design

## Goal

Add a checked-in setup script so a future ChatGPT Codex Cloud environment can install the exact Foundry toolchain this repository was validated with before the agent session starts.

## Constraints

- This repository is a Foundry project, not an npm or Python project.
- The implementation handoff notes that older Foundry versions were incompatible with the installed OpenZeppelin dependency.
- The known-good toolchain for this repo is `1.6.0-nightly`.
- Secrets and live broadcast execution should stay out of setup.

## Recommended Approach

Add a repo-root `codex-cloud-setup.sh` that:

1. Installs the Foundry bootstrap.
2. Persists `~/.foundry/bin` into `~/.bashrc` for later agent shells.
3. Installs Foundry `1.6.0-nightly` with `foundryup -v 1.6.0-nightly`.
4. Verifies the environment with `forge --version` and `forge test`.

## Why This Approach

- It matches the toolchain already proven to work in this repo.
- It keeps setup focused on reproducible tooling rather than deployment secrets.
- It fails fast during environment provisioning if the toolchain is wrong.

## Documentation Changes

Add a short `README.md` section showing that Codex Cloud should run `./codex-cloud-setup.sh` during environment setup, and note that real broadcast runs still require local secret handling.
