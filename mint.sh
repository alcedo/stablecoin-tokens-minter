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
  if ! SCRIPT_PREFLIGHT="$(python3 - "$SCRIPT_PATH" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
source = path.read_text()

config_match = re.search(
    r'config\s*=\s*TokenConfig\s*\(\s*\{\s*name:\s*"(?P<name>[^"]*)"\s*,\s*symbol:\s*"(?P<symbol>[^"]*)"\s*,\s*decimals:\s*(?P<decimals>\d+)\s*,\s*finalOwner:\s*(?P<owner>[^}]+?)\s*}\s*\)\s*;',
    source,
    re.S,
)
if not config_match:
    sys.exit("Unable to parse TokenConfig from script/DeployAndDistribute.s.sol")

recipient_matches = re.findall(
    r'Recipient\s*\(\s*\{\s*to:\s*(?P<to>[^,]+?)\s*,\s*amount:\s*(?P<amount>[^}]+?)\s*}\s*\)',
    source,
    re.S,
)

count = len(recipient_matches)
total = 0
for _to, amount_expr in recipient_matches:
    amount_expr = amount_expr.strip().replace('_', '')
    ether_match = re.fullmatch(r'(\d+)\s+ether', amount_expr)
    if ether_match:
        total += int(ether_match.group(1)) * 10**18
        continue
    if re.fullmatch(r'\d+', amount_expr):
        total += int(amount_expr)
        continue
    sys.exit(f"Unable to parse recipient amount expression: {amount_expr}")

print(config_match.group('name'))
print(config_match.group('symbol'))
print(config_match.group('decimals'))
print(config_match.group('owner').strip())
print(count)
print(total)
PY
)"; then
    die "Unable to parse token preflight data from $SCRIPT_PATH"
  fi

  mapfile -t preflight_lines <<<"$SCRIPT_PREFLIGHT"
  [ "${#preflight_lines[@]}" -eq 6 ] || die "Unexpected token preflight data from $SCRIPT_PATH"

  TOKEN_NAME="${preflight_lines[0]}"
  TOKEN_SYMBOL="${preflight_lines[1]}"
  TOKEN_DECIMALS="${preflight_lines[2]}"
  FINAL_OWNER="${preflight_lines[3]}"
  RECIPIENT_COUNT="${preflight_lines[4]}"
  TOTAL_MINT_AMOUNT="${preflight_lines[5]}"
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
