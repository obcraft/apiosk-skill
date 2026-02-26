# Security Policy

## Scope

`apiosk-skill` is an address-only gateway access skill.

## Data Handling

- Reads wallet address from:
  - `~/.apiosk/wallet.txt` (preferred)
  - `~/.apiosk/wallet.json` (`address` field only, backward compatibility)
  - `APIOSK_WALLET_ADDRESS` env var
- Writes:
  - `~/.apiosk/wallet.txt` (wallet address only)
  - `~/.apiosk/config.json` (gateway/rpc configuration)
- Does not store signing key material.
- Does not ask for signing key material.

## Network Access

The scripts call:

- `https://gateway.apiosk.com`
- `https://mainnet.base.org` (read-only balance queries when `cast` is installed)

## Command Safety

- No pipe-to-shell install patterns.
- No dynamic code execution (`eval`/`source` from remote input).
- No dependency download commands in scripts.

## Reporting

Report security issues to `security@apiosk.com`.
