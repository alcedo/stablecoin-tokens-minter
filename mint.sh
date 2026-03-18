#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CHAIN_ALIAS=""
BROADCAST=false
CONFIRM_MAINNET=false
SCRIPT_PATH="$SCRIPT_DIR/script/DeployAndDistribute.s.sol"

die() {
  echo "Error: $*" >&2
  exit 1
}

usage() {
  cat <<'EOF_USAGE'
Usage: ./mint.sh --chain <alias> [--broadcast] [--confirm-mainnet]

Examples:
  ./mint.sh --chain anvil
  ./mint.sh --chain sepolia --broadcast
  ./mint.sh --chain ethereum --broadcast --confirm-mainnet
EOF_USAGE
}

resolve_rpc_url() {
  local value

  value="$(printenv "$RPC_URL_ENV_VAR" 2>/dev/null || true)"
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
    return 0
  fi

  if [ -n "$RPC_URL_DEFAULT" ]; then
    printf '%s\n' "$RPC_URL_DEFAULT"
    return 0
  fi

  return 1
}

load_script_preflight() {
  # Load .env file if present (without exporting, just for this shell)
  if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$SCRIPT_DIR/.env"
    set +a
  fi

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
  TOTAL_MINT_AMOUNT=$(( RECIPIENT_AMOUNT + RECIPIENT2_AMOUNT ))
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --chain)
      [ "$#" -ge 2 ] || die "Missing value for --chain"
      CHAIN_ALIAS="$2"
      shift 2
      ;;
    --broadcast)
      BROADCAST=true
      shift
      ;;
    --confirm-mainnet)
      CONFIRM_MAINNET=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[ -n "$CHAIN_ALIAS" ] || die "Missing required --chain <alias>"

. "$SCRIPT_DIR/config/chains.sh"
resolve_chain "$CHAIN_ALIAS"

RPC_URL="$(resolve_rpc_url)" || die "Set $RPC_URL_ENV_VAR before running for chain '$CHAIN_ALIAS'"
load_script_preflight

if [ "$BROADCAST" = true ] && [ -z "${PRIVATE_KEY:-}" ]; then
  die "Set PRIVATE_KEY before using --broadcast"
fi

if [ "$IS_MAINNET" = true ] && [ "$BROADCAST" = true ] && [ "$CONFIRM_MAINNET" != true ]; then
  die "Refusing mainnet broadcast without --confirm-mainnet"
fi

echo "Chain alias: $CHAIN_ALIAS"
echo "Chain ID: $CHAIN_ID"
if [ -n "$EXPLORER_BASE_URL" ]; then
  echo "Explorer: $EXPLORER_BASE_URL"
else
  echo "Explorer: not configured"
fi

echo "Token name: $TOKEN_NAME"
echo "Token symbol: $TOKEN_SYMBOL"
echo "Token decimals: $TOKEN_DECIMALS"
echo "Final owner: $FINAL_OWNER"
echo "Recipient count: $RECIPIENT_COUNT"
echo "Total mint amount: $TOTAL_MINT_AMOUNT"

if [ "$BROADCAST" = true ]; then
  echo "Mode: broadcast"
else
  echo "Mode: simulation"
  echo "No transactions will be sent."
fi

COMMAND=(forge script script/DeployAndDistribute.s.sol:DeployAndDistribute --rpc-url "$RPC_URL")
if [ "$BROADCAST" = true ]; then
  COMMAND+=(--broadcast)
fi

echo "Running: ${COMMAND[*]}"
"${COMMAND[@]}"
