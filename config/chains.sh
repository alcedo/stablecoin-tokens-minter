#!/usr/bin/env bash

resolve_chain() {
  case "$1" in
    anvil)
      CHAIN_ID=31337
      RPC_URL_ENV_VAR="ANVIL_RPC_URL"
      RPC_URL_DEFAULT="http://127.0.0.1:8545"
      EXPLORER_BASE_URL=""
      IS_MAINNET=false
      ;;
    sepolia)
      CHAIN_ID=11155111
      RPC_URL_ENV_VAR="SEPOLIA_RPC_URL"
      RPC_URL_DEFAULT=""
      EXPLORER_BASE_URL="https://sepolia.etherscan.io"
      IS_MAINNET=false
      ;;
    base-sepolia)
      CHAIN_ID=84532
      RPC_URL_ENV_VAR="BASE_SEPOLIA_RPC_URL"
      RPC_URL_DEFAULT=""
      EXPLORER_BASE_URL="https://sepolia.basescan.org"
      IS_MAINNET=false
      ;;
    ethereum)
      CHAIN_ID=1
      RPC_URL_ENV_VAR="ETHEREUM_RPC_URL"
      RPC_URL_DEFAULT=""
      EXPLORER_BASE_URL="https://etherscan.io"
      IS_MAINNET=true
      ;;
    base)
      CHAIN_ID=8453
      RPC_URL_ENV_VAR="BASE_RPC_URL"
      RPC_URL_DEFAULT=""
      EXPLORER_BASE_URL="https://basescan.org"
      IS_MAINNET=true
      ;;
    *)
      echo "Unsupported chain alias: $1" >&2
      return 1
      ;;
  esac
}
