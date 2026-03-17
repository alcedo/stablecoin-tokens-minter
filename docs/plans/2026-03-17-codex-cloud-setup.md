# Codex Cloud Setup Script Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a checked-in Codex Cloud setup script that installs the known-good Foundry toolchain for this repository and document how to use it.

**Architecture:** Keep the change small and repo-local. Add one bootstrap script at the repository root, keep the script responsible only for Foundry installation and validation, and add a short README section that tells Codex Cloud to run it during environment setup.

**Tech Stack:** Bash, Foundry, repository docs

---

### Task 1: Add the setup script

**Files:**
- Create: `codex-cloud-setup.sh`

**Step 1: Write the script**

- Use `set -euo pipefail`.
- Install the Foundry bootstrap with `curl -L https://foundry.paradigm.xyz | bash`.
- Persist `export PATH="$HOME/.foundry/bin:$PATH"` into `~/.bashrc` if it is not already present.
- Export the same path in the current shell.
- Install `1.6.0-nightly` with `foundryup -v 1.6.0-nightly`.
- Verify with `forge --version` and `forge test`.

**Step 2: Make it executable**

Run: `chmod +x codex-cloud-setup.sh`
Expected: no output

### Task 2: Document usage

**Files:**
- Modify: `README.md`

**Step 1: Add a Codex Cloud section**

- Explain that Codex Cloud should execute `./codex-cloud-setup.sh` during environment setup.
- Note that the script installs the pinned Foundry version and runs `forge test`.
- Note that real `--broadcast` runs still require local secrets and should not rely on setup-time secret access.

### Task 3: Verify the change

**Files:**
- Test: `codex-cloud-setup.sh`
- Test: `README.md`

**Step 1: Verify script syntax**

Run: `bash -n codex-cloud-setup.sh`
Expected: success with no output

**Step 2: Verify documentation references**

Run: `rg -n "codex-cloud-setup.sh|Codex Cloud" README.md`
Expected: matches in the new README section
