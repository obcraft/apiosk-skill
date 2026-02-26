#!/bin/bash
# List Apiosk APIs with optional listing group filters.

set -e

GATEWAY_URL="https://gateway.apiosk.com"
TYPE_FILTER=""
SEARCH=""
LIMIT="50"

print_help() {
  echo "Usage: ./list-apis.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --type TYPE      api | datasets | compute"
  echo "  --search QUERY   Filter by search text"
  echo "  --limit N        Limit results (default: 50)"
  echo "  --help           Show help"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      TYPE_FILTER="$2"
      shift 2
      ;;
    --search)
      SEARCH="$2"
      shift 2
      ;;
    --limit)
      LIMIT="$2"
      shift 2
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

if [[ -n "$TYPE_FILTER" && ! "$TYPE_FILTER" =~ ^(api|datasets|compute)$ ]]; then
  echo "Error: --type must be one of: api, datasets, compute"
  exit 1
fi

if [[ -n "$TYPE_FILTER" ]]; then
  ENDPOINT="$GATEWAY_URL/types/$TYPE_FILTER/v1?limit=$LIMIT"
else
  ENDPOINT="$GATEWAY_URL/v1/apis?limit=$LIMIT"
fi

if [[ -n "$SEARCH" ]]; then
  ENDPOINT="${ENDPOINT}&search=${SEARCH}"
fi

echo "Apiosk listings"
if [[ -n "$TYPE_FILTER" ]]; then
  echo "Group: $TYPE_FILTER"
else
  echo "Group: all"
fi
echo ""

APIS="$(curl -s "$ENDPOINT")"

if ! echo "$APIS" | jq empty >/dev/null 2>&1; then
  echo "Failed to fetch listings from $ENDPOINT"
  echo "$APIS"
  exit 1
fi

COUNT="$(echo "$APIS" | jq '.apis | length')"
if [[ "$COUNT" -eq 0 ]]; then
  echo "No listings found."
  exit 0
fi

echo "$APIS" | jq -r '.apis[] | "\(.slug)\t$\(.price_usd)/req\t\(.category)\t\(.description)"' | column -t -s $'\t'
echo ""
echo "Total listings: $COUNT"
