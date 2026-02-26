#!/bin/bash
# Check USDC balance for your configured Apiosk wallet address

set -euo pipefail

WALLET_TXT="$HOME/.apiosk/wallet.txt"
WALLET_JSON="$HOME/.apiosk/wallet.json"
CONFIG_FILE="$HOME/.apiosk/config.json"

if [[ -f "$WALLET_TXT" ]]; then
  WALLET_ADDRESS="$(tr -d '[:space:]' < "$WALLET_TXT")"
elif [[ -f "$WALLET_JSON" ]]; then
  WALLET_ADDRESS="$(jq -r '.address // empty' "$WALLET_JSON")"
else
  echo "Wallet not found. Run ./setup-wallet.sh first."
  exit 1
fi

if [[ -z "$WALLET_ADDRESS" ]]; then
  echo "Wallet address is empty."
  exit 1
fi

RPC_URL=$(jq -r '.rpc_url' "$CONFIG_FILE")
USDC_CONTRACT=$(jq -r '.usdc_contract' "$CONFIG_FILE")
GATEWAY_URL=$(jq -r '.gateway_url' "$CONFIG_FILE")

echo "Apiosk Wallet Balance"
echo ""
echo "Address: $WALLET_ADDRESS"
echo ""

# Check USDC balance on-chain
if command -v cast &> /dev/null; then
  BALANCE_WEI=$(cast call "$USDC_CONTRACT" "balanceOf(address)(uint256)" "$WALLET_ADDRESS" --rpc-url "$RPC_URL")
  BALANCE_USDC=$(echo "scale=2; $BALANCE_WEI / 1000000" | bc)
  echo "USDC Balance: $BALANCE_USDC USDC"
else
  echo "Install Foundry to check on-chain balance:"
  echo "https://book.getfoundry.sh/getting-started/installation"
fi

# Check usage via Apiosk gateway
USAGE=$(curl -s "$GATEWAY_URL/v1/balance?address=$WALLET_ADDRESS")

if [ $? -eq 0 ]; then
  echo ""
  echo "📊 Apiosk Usage:"
  echo "$USAGE" | jq
else
  echo ""
  echo "Could not fetch usage stats from gateway"
fi

echo ""
echo "Top up at: https://bridge.base.org"
echo ""
