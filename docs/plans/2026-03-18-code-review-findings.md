# Code Review Findings — 2026-03-18

## Overview
Code review of the shell wrapper (`mint.sh`), Solidity deploy script, `.env.example`, tests, and supporting scripts. 8 issues confirmed for fixing, 2 skipped.

## Issues to Fix

### 1. [High] `.env.example` — unquoted values with spaces
- **File:** `.env.example` (lines 4, 11, 16, 18)
- **Problem:** `TOKEN_NAME=Example Stablecoin` is interpreted by bash as setting `TOKEN_NAME=Example` then executing `Stablecoin` as a command. Same for mnemonic placeholder values.
- **Fix:** Quote all values containing spaces: `TOKEN_NAME="Example Stablecoin"`, `OWNER="your twelve word mnemonic phrase goes here ..."`, etc.

### 2. [High] Bash arithmetic overflow on wei amounts
- **File:** `mint.sh` (line 67)
- **Problem:** `$(( RECIPIENT_AMOUNT + RECIPIENT2_AMOUNT ))` uses 64-bit signed integer math. ERC-20 wei amounts (e.g. 10^21) exceed 2^63 and silently overflow to garbage values. Example: 1000000000000000000000 + 500000000000000000000 = 4659767778871345152 (wrong).
- **Fix:** Replace with `TOTAL_MINT_AMOUNT=$(echo "$RECIPIENT_AMOUNT + $RECIPIENT2_AMOUNT" | bc)`.

### 3. [Medium] Simulation mode fails without DEPLOYER_KEY
- **Files:** `mint.sh` (lines 103-105), `script/DeployAndDistribute.s.sol` (line 92)
- **Problem:** `mint.sh` only requires `DEPLOYER_KEY` when `--broadcast` is set, but `forge script` always executes `run()` which calls `vm.envUint("DEPLOYER_KEY")` unconditionally. Simulation mode crashes.
- **Fix:** Either use `vm.envOr("DEPLOYER_KEY", uint256(0))` in Solidity for non-broadcast runs, or require DEPLOYER_KEY in all modes in the shell script.

### 4. [Medium] Shell test completely broken
- **File:** `test/mint.sh.test`
- **Problem:** Test expects the old "parse Solidity source" flow. Current `mint.sh` reads from `.env` and derives addresses via `cast`. Both test cases fail immediately on env var validation. Test also only mocks `forge` but not `cast`.
- **Fix:** Full rewrite — create a valid `.env` in the temp dir, mock both `forge` and `cast`, update all assertions to match current output format.

### 5. [Low] `SCRIPT_PATH` dead variable
- **File:** `mint.sh` (line 8)
- **Problem:** Assigned but never used. The forge command on line 133 hardcodes the path instead.
- **Fix:** Remove the variable, or wire it into the forge command.

### 6. [Low] Relative path in forge command — CWD-dependent
- **File:** `mint.sh` (line 133)
- **Problem:** `forge script script/DeployAndDistribute.s.sol:DeployAndDistribute` uses a relative path. Running mint.sh from outside the repo root breaks both `foundry.toml` discovery and script path resolution.
- **Fix:** Add `cd "$SCRIPT_DIR"` before the forge invocation. This also makes the `SCRIPT_PATH` variable useful if kept.

### 7. [Low] `FOUNDATION_LINE` typo in codex-cloud-setup.sh
- **File:** `codex-cloud-setup.sh` (line 3)
- **Problem:** Every other variable uses the `FOUNDRY_` prefix. `FOUNDATION_LINE` is the sole outlier.
- **Fix:** Rename to `FOUNDRY_LINE`.

### 8. [Low] README out of sync with current workflow
- **File:** `README.md`
- **Problem:** Tells users to edit hardcoded Solidity config (now env-driven) and references nightly Foundry (now stable). Would mislead new users.
- **Fix:** Update README to reflect env-driven config, `.env.example` copy workflow, and stable Foundry.

## Skipped (not worth fixing now)

- **Hardcoded `RECIPIENT_COUNT=2`** — shell and Solidity are in sync; purely hypothetical future concern.
- **Missing `pipefail` in mint.sh** — no pipes exist in the script; zero current impact.
