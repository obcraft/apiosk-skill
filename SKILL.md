---
name: apiosk-gateway
description: Handle Apiosk x402 payments, browse and publish listing types, and create signed payment proofs for paid gateway requests.
---

# apiosk-gateway

Use this skill when calling `https://gateway.apiosk.com` for paid endpoints, publishing APIs, or working with listing-type discovery.

## When to use

- You need to call an Apiosk endpoint and receive `402 Payment Required`.
- You need to create an `x-payment` proof and retry the request.
- You need to browse listing groups (`/types`, `/types/:listing_type/v1`, `/v1/apis`).
- You need to publish/update/delete APIs through gateway management routes.

## Core endpoints

- `GET /types`
- `GET /types/:listing_type/v1`
- `GET /v1/apis`
- `GET /v1/balance?address=0x...`
- `GET /v1/usage?address=0x...&period=all|today|week|month`
- `POST /v1/apis/register`
- `POST /v1/apis/:slug`
- `GET /v1/apis/mine?wallet=0x...`
- `DELETE /v1/apis/:slug?wallet=0x...`
- `ANY /:api_slug/*path` (paid proxy calls)

## Listing types

- Public browse groups:
  - `api`
  - `datasets`
  - `compute`
- Internal listing types supported by the gateway data model:
  - `api`
  - `skill`
  - `product`
  - `dataset`
  - `service`
  - `connector`

For discovery, always start with:
1. `GET /types`
2. `GET /types/<group>/v1`
3. `GET /v1/apis` with `search`, `category`, `sort`, `order`, `limit`, `offset`

## Payment flow (x402)

1. Send the request without `x-payment`.
2. If response is `402`, parse `accepts[0]` from JSON:
   - `scheme`
   - `network`
   - `maxAmountRequired`
   - `payTo`
   - `asset`
   - `maxTimeoutSeconds`
   - `extra.name` and `extra.version` (token EIP-712 domain)
3. Build a `TransferWithAuthorization` payload and sign it with EIP-712.
4. Create proof:
   - `x402Version: 1`
   - `scheme`
   - `network`
   - `payload.signature`
   - `payload.authorization` (`from`, `to`, `value`, `validAfter`, `validBefore`, `nonce`)
5. Base64-encode the proof JSON.
6. Retry the exact same HTTP method/path/body with header `x-payment: <base64-proof>`.

If the retry returns `402` again, generate a new `nonce` and fresh `validBefore` and retry once more.

## Create payment proof (reference)

Use EIP-3009 `TransferWithAuthorization` typed data:

- Domain:
  - `name = requirement.extra.name` (fallback `USD Coin`)
  - `version = requirement.extra.version` (fallback `2`)
  - `chainId` from `requirement.network`
  - `verifyingContract = requirement.asset`
- Types:
  - `from`, `to`, `value`, `validAfter`, `validBefore`, `nonce`
- Message:
  - `from = caller wallet`
  - `to = requirement.payTo`
  - `value = requirement.maxAmountRequired`
  - `validAfter = 0`
  - `validBefore = now + requirement.maxTimeoutSeconds`
  - `nonce = random 32-byte hex`

Network-to-chainId defaults:

- `base-sepolia` => `84532`
- `base` => `8453`
- `ethereum` => `1`
- `polygon` => `137`
- `arbitrum` => `42161`

## Publishing APIs (upload flow)

Use `POST /v1/apis/register` with JSON:

```json
{
  "name": "My API",
  "slug": "my-api",
  "endpoint_url": "https://example.com",
  "price_usd": 0.01,
  "description": "My paid API",
  "owner_wallet": "0x...",
  "category": "data"
}
```

Required auth headers for register/update/mine/delete:

- `x-wallet-address`
- `x-wallet-signature`
- `x-wallet-timestamp`
- `x-wallet-nonce`

Canonical signed message:

```text
Apiosk auth
action:<action>
wallet:<lowercase_wallet>
resource:<resource>
timestamp:<unix_seconds>
nonce:<nonce>
```

Action/resource mapping:

- register: `action=register_api`, `resource=register:<slug>`
- update: `action=update_api`, `resource=update:<slug>`
- mine: `action=my_apis`, `resource=mine:<wallet>`
- delete: `action=delete_api`, `resource=delete:<slug>`

## Agent behavior requirements

- Treat `402` as a normal state transition, not a terminal failure.
- Never invent payment requirements; always use values from the latest `402` response.
- Preserve method/path/body between initial and paid retry.
- Prefer lowest-cost endpoint when multiple options satisfy the same task.
- Surface cost before paid calls when possible (`price_usd` from API discovery endpoints).
- If publishing fails with `Unauthorized`, re-check wallet signature inputs (`action`, `resource`, lowercase wallet, timestamp freshness).
