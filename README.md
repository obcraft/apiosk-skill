# Apiosk Gateway Skill

Use Apiosk paid APIs through x402 (`402 Payment Required`) and discover the latest listing groups.

## Install

```bash
npx skills add obcraft/apiosk-skill --skill apiosk-gateway
```

## Quick Start

```bash
# Save wallet address locally (address only, no local signing key storage)
./setup-wallet.sh --wallet 0xYourWalletAddress

# Browse listings
./list-apis.sh
./list-apis.sh --type datasets
./list-apis.sh --type compute

# Probe an API (this may return 402)
./call-api.sh weather --params '{"city":"Amsterdam"}'
```

## Notes

- This skill does not auto-sign x402 payment proofs.
- On `402`, use an x402 SDK/client signer and retry with `x-payment`.
- Discovery groups: `api`, `datasets`, `compute`.

## Security

- The skill stores only your wallet address in `~/.apiosk/wallet.txt`.
- No signing key material is generated, stored, or transmitted by this skill.
- All network calls use `https://gateway.apiosk.com`.
