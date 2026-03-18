#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CHAIN_ALIAS=""
BROADCAST=false
CONFIRM_MAINNET=false

FINAL_OWNER=""
RECIPIENT_COUNT=""
TOTAL_MINT_AMOUNT=""
TOKEN_NAME=""
TOKEN_SYMBOL=""
TOKEN_DECIMALS=""


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

load_env_file() {
  if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$SCRIPT_DIR/.env"
    set +a
  fi
}

validate_address() {
  local value="$1"
  [[ "$value" =~ ^0x[0-9a-fA-F]{40}$ ]]
}

load_script_preflight() {
  local recipient_index recipient_address recipient_amount

  load_env_file

  [ -n "${TOKEN_NAME:-}" ] || die "TOKEN_NAME not set — check your .env file"
  [ -n "${TOKEN_SYMBOL:-}" ] || die "TOKEN_SYMBOL not set — check your .env file"
  [ -n "${TOKEN_DECIMALS:-}" ] || die "TOKEN_DECIMALS not set — check your .env file"
  [ -n "${OWNER_ADDRESS:-}" ] || die "OWNER_ADDRESS not set — check your .env file"
  [ -n "${RECIPIENT_COUNT:-}" ] || die "RECIPIENT_COUNT not set — check your .env file"

  validate_address "$OWNER_ADDRESS" || die "OWNER_ADDRESS must be a 0x-prefixed 20-byte address"
  [[ "$TOKEN_DECIMALS" =~ ^[0-9]+$ ]] || die "TOKEN_DECIMALS must be an integer"
  [[ "$RECIPIENT_COUNT" =~ ^[0-9]+$ ]] || die "RECIPIENT_COUNT must be an integer"
  [ "$RECIPIENT_COUNT" -gt 0 ] || die "RECIPIENT_COUNT must be greater than zero"

  FINAL_OWNER="$OWNER_ADDRESS"
  TOTAL_MINT_AMOUNT=0

  for recipient_index in $(seq 1 "$RECIPIENT_COUNT"); do
    recipient_address_var="RECIPIENT_${recipient_index}_ADDRESS"
    recipient_amount_var="RECIPIENT_${recipient_index}_AMOUNT"

    recipient_address="${!recipient_address_var:-}"
    recipient_amount="${!recipient_amount_var:-}"

    [ -n "$recipient_address" ] || die "$recipient_address_var not set — check your .env file"
    [ -n "$recipient_amount" ] || die "$recipient_amount_var not set — check your .env file"
    validate_address "$recipient_address" || die "$recipient_address_var must be a 0x-prefixed 20-byte address"
    [[ "$recipient_amount" =~ ^[0-9]+$ ]] || die "$recipient_amount_var must be an integer"
    [ "$recipient_amount" != "0" ] || die "$recipient_amount_var must be greater than zero"

    TOTAL_MINT_AMOUNT="$(TOTAL_MINT_AMOUNT="$TOTAL_MINT_AMOUNT" RECIPIENT_AMOUNT_TO_ADD="$recipient_amount" python - <<'PY_SUM'
import os
print(int(os.environ["TOTAL_MINT_AMOUNT"]) + int(os.environ["RECIPIENT_AMOUNT_TO_ADD"]))
PY_SUM
)"
  done
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

cd "$SCRIPT_DIR"
COMMAND=(forge script script/DeployAndDistribute.s.sol:DeployAndDistribute --rpc-url "$RPC_URL")
if [ "$BROADCAST" = true ]; then
  COMMAND+=(--broadcast)
fi

echo "Running: ${COMMAND[*]}"
"${COMMAND[@]}"
