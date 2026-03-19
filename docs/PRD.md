# Foundry ERC20 Deploy-and-Mint CLI Plan

## Summary
Build a greenfield Foundry project that exposes a thin CLI wrapper for deploying a new mintable ERC20 and distributing tokens to many recipients on a selected EVM chain alias. The user-facing command is a shell entrypoint, while token metadata and recipient allocations remain authored directly in the Solidity script for each run.

## Implementation Changes
- Create a Foundry workspace with OpenZeppelin contracts as the only core dependency.
- Add a token contract at `/Users/victor/Documents/workspace/AI-General-Workspace/one-shot-erc20-token-test/src/MintableERC20.sol`:
  - Extend `ERC20` and `Ownable`.
  - Constructor signature: `constructor(string memory name_, string memory symbol_, uint8 decimals_, address initialOwner_)`.
  - Store custom decimals in an immutable/private variable and override `decimals()`.
  - Expose `mint(address to, uint256 amount) external onlyOwner`.
- Add a deployment/distribution script at `/Users/victor/Documents/workspace/AI-General-Workspace/one-shot-erc20-token-test/script/DeployAndDistribute.s.sol`:
  - Define script-level constants or helper-returned values for `TOKEN_NAME`, `TOKEN_SYMBOL`, `TOKEN_DECIMALS`, `FINAL_OWNER`, and `Recipient[]`.
  - Define `struct Recipient { address to; uint256 amount; }`.
  - Perform pre-broadcast validation for non-empty recipients, non-zero addresses, non-zero amounts, and duplicate addresses.
  - Deploy the token with the broadcaster as `initialOwner`.
  - Loop over recipients and call `mint` once per recipient.
  - Transfer ownership to `FINAL_OWNER` after minting when `FINAL_OWNER != broadcaster`.
  - Log deployed token address, total minted amount, recipient count, final owner, and per-recipient mint results.
- Add a thin CLI wrapper at `/Users/victor/Documents/workspace/AI-General-Workspace/one-shot-erc20-token-test/mint.sh`:
  - Interface: `./mint.sh --chain <alias> [--broadcast] [--confirm-mainnet]`.
  - Default behavior is dry-run/simulation; only pass `--broadcast` to `forge script` when explicitly requested.
  - Resolve `<alias>` through a sourced shell config such as `/Users/victor/Documents/workspace/AI-General-Workspace/one-shot-erc20-token-test/config/chains.sh`.
  - Each alias entry must set `CHAIN_ID`, `RPC_URL`, `EXPLORER_BASE_URL`, and `IS_MAINNET`.
  - Require `DEPLOYER_KEY` in env for broadcast runs.
  - For `IS_MAINNET=true`, refuse broadcast unless `--confirm-mainnet` is also present.
  - Print a preflight summary before invoking Foundry: chain alias, chain ID, token metadata, final owner, recipient count, and total mint amount.
- Add starter chain aliases in `config/chains.sh` for at least one testnet and one mainnet example so the alias mechanism is exercised end to end.

## Public Interfaces
- CLI:
  - `--chain <alias>` selects the configured network.
  - `--broadcast` sends transactions; omission keeps the run as simulation.
  - `--confirm-mainnet` is required in addition to `--broadcast` for aliases marked as mainnet.
- Solidity:
  - `MintableERC20.mint(address,uint256)` is the only custom token action in v1.
  - No `batchMint`, existing-token flow, config-file inputs, or repeated CLI recipient flags in v1.
- Script authoring surface:
  - Operators edit token params and recipients directly in `DeployAndDistribute.s.sol` before running the wrapper.

## Test Plan
- Unit tests in `/Users/victor/Documents/workspace/AI-General-Workspace/one-shot-erc20-token-test/test/MintableERC20.t.sol`:
  - Constructor sets name, symbol, decimals, and initial owner correctly.
  - Only owner can mint.
  - Mint updates balances and total supply.
- Script/integration tests in `/Users/victor/Documents/workspace/AI-General-Workspace/one-shot-erc20-token-test/test/DeployAndDistribute.t.sol`:
  - Successful deploy-and-distribute on Anvil with multiple recipients.
  - Ownership transfers to `FINAL_OWNER` after all mints.
  - Validation rejects empty recipient sets, zero addresses, zero amounts, and duplicates.
  - Wrapper/simulation path does not require `--broadcast`.
  - Mainnet-marked aliases fail without `--confirm-mainnet`.
- Acceptance scenario:
  - Edit script constants and recipients, run `./mint.sh --chain <test-alias>` for simulation, then `./mint.sh --chain <test-alias> --broadcast` and verify the logged token address and minted balances.

## Assumptions
- This workspace is greenfield and not yet a git repo; the implementation should initialize the project structure from scratch.
- V1 always deploys a new ERC20 before distribution; minting an already deployed token is out of scope.
- Recipient data and token params stay hardcoded in Solidity for v1, per your preference.
- The configured `owner` means final post-run owner, not the temporary deploying broadcaster.
- Per-recipient mint transactions are intentional in v1 even though a single `batchMint` would be more gas-efficient.
