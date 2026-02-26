#!/bin/bash
# Apiosk Wallet Setup - address-only configuration (no local signing key storage)

set -euo pipefail

WALLET_DIR="$HOME/.apiosk"
WALLET_TXT="$WALLET_DIR/wallet.txt"
CONFIG_FILE="$WALLET_DIR/config.json"
FORCE="false"
ADDRESS=""

print_help() {
  echo "Usage: ./setup-wallet.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --wallet ADDRESS   Wallet address to use (0x...)"
  echo "  --force            Overwrite existing ~/.apiosk/wallet.txt"
  echo "  --help             Show this help"
}

validate_wallet() {
  [[ "$1" =~ ^0x[a-fA-F0-9]{40}$ ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --wallet)
      ADDRESS="$2"
      shift 2
      ;;
    --force)
      FORCE="true"
      shift
      ;;
    --help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      print_help
      exit 1
      ;;
  esac
done

echo "Apiosk Wallet Setup (address only)"
echo ""

mkdir -p "$WALLET_DIR"

if [[ -f "$WALLET_TXT" && "$FORCE" != "true" ]]; then
  echo "Wallet already exists at $WALLET_TXT"
  echo "Use --force to replace it."
  exit 1
fi

if [[ -z "$ADDRESS" ]]; then
  read -r -p "Enter wallet address (0x...): " ADDRESS
fi

if ! validate_wallet "$ADDRESS"; then
  echo "Error: invalid wallet address format."
  exit 1
fi

printf '%s\n' "$ADDRESS" > "$WALLET_TXT"
chmod 600 "$WALLET_TXT"

cat > "$CONFIG_FILE" << EOF
{
  "rpc_url": "https://mainnet.base.org",
  "chain_id": 8453,
  "usdc_contract": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  "gateway_url": "https://gateway.apiosk.com",
  "daily_limit_usdc": 100.0,
  "per_request_limit_usdc": 1.0
}
EOF

echo ""
echo "Wallet address saved."
echo "Address: $ADDRESS"
echo "File: $WALLET_TXT"
echo ""
echo "No signing key material is stored by this skill."
echo ""
echo "Fund your wallet with USDC on Base:"
echo "  https://bridge.base.org"
echo ""
echo "Check balance: ./check-balance.sh"
