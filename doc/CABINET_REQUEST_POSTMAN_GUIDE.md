# Cabinet Request Postman Guide

**কী জিনিস:** ক্যাবিনেট রিকোয়েস্ট তৈরি থেকে কোট একসেপ্ট, বুকিং, পেমেন্ট আর প্রোভাইডার জব শেষ—সবটা Postman দিয়ে কীভাবে হিট করবেন তার ধাপবিধি।

Base URL:

`http://localhost:3000/api/v1`

Use Bearer tokens from your existing auth endpoints.

## APIs by role (quick list)

Paths are under the base URL above. Admin-only flows (list queue, assign provider, dev simulate-paid) are in sections 3–4 and 16—নিচে দেখুন।

### Customer

| Method | Path |
|--------|------|
| `POST` | `/cabinet-requests` |
| `GET` | `/cabinet-requests/me` |
| `GET` | `/cabinet-requests/:requestId` |
| `POST` | `/cabinet-requests/:requestId/accept-quote` |
| `POST` | `/cabinet-requests/:requestId/cancel` |
| `GET` | `/bookings/:bookingId` |
| `POST` | `/payments/intent` (or `/payments/intents`) |
| `PATCH` | `/bookings/:bookingId/cancel` |

### Provider

| Method | Path |
|--------|------|
| `PATCH` | `/cabinet-requests/:requestId/review-status` |
| `PATCH` | `/cabinet-requests/:requestId/quote` |
| `GET` | `/bookings/provider/me` |
| `PATCH` | `/bookings/:bookingId/start` |
| `PATCH` | `/bookings/:bookingId/complete` |
| `PATCH` | `/bookings/:bookingId/cancel` |

### Public (no auth)

| Method | Path |
|--------|------|
| `GET` | `/payments/config` |

## Required setup before testing

You need:

- one customer token
- one provider token
- (optional) one admin token — only for sections **3**, **4**, and **16** (list queue, assign provider, dev simulate-paid)
- a valid `townId`
- a valid `serviceId` for `Custom Kitchen Cabinets`
- a provider user that already has a verified `ProviderProfile`

If the cabinet service does not exist yet, create it first using your existing catalog admin flow or insert it in the database.

Suggested service values:

- `name`: `Custom Kitchen Cabinets`
- `slug`: `custom-kitchen-cabinets`

## 1. Customer creates cabinet request

`POST /cabinet-requests`

Headers:

- `Authorization: Bearer <customer_token>`
- Do not set `Content-Type` manually in Postman when using `form-data`

Body:

Use `form-data`, not raw JSON.

Text fields:

- `townId` = `PUT_TOWN_ID_HERE`
- `serviceId` = `PUT_CABINET_SERVICE_ID_HERE`
- `customerPhone` = `+1 647 000 0000`
- `timeline` = `Within 1 month`
- `notes` = `Need full kitchen cabinet replacement.`
- `style` = `Shaker`
- `selectedAddons` = `["soft_close","hardware"]`
- `visitAddress` = `{"line1":"123 Main Street","line2":"Unit 5","city":"Toronto","postalCode":"M5V 1A1"}`

File fields:

- `photos` = first image file
- `photos` = second image file
- `photos` = third image file

Example field layout:

```text
townId: PUT_TOWN_ID_HERE
serviceId: PUT_CABINET_SERVICE_ID_HERE
customerPhone: +1 647 000 0000
timeline: Within 1 month
notes: Need full kitchen cabinet replacement.
style: Shaker
selectedAddons: ["soft_close","hardware"]
visitAddress: {"line1":"123 Main Street","line2":"Unit 5","city":"Toronto","postalCode":"M5V 1A1"}
photos: <file-1>
photos: <file-2>
photos: <file-3>
```

Expected:

- status `201`
- request status should be `submitted`
- response `photos` will be saved as backend-hosted URLs under `/uploads/cabinet-requests/...`

## 2. Customer lists own requests

`GET /cabinet-requests/me`

Headers:

- `Authorization: Bearer <customer_token>`

Optional query:

- `status=submitted`

## 3. Admin lists request queue

`GET /cabinet-requests`

Headers:

- `Authorization: Bearer <admin_token>`

Optional query:

- `status=submitted`

## 4. Admin assigns provider

`PATCH /cabinet-requests/:requestId/assign-provider`

Headers:

- `Authorization: Bearer <admin_token>`
- `Content-Type: application/json`

Body:

```json
{
  "providerId": "PUT_PROVIDER_USER_ID_HERE"
}
```

Expected:

- assigned provider is stored
- request usually moves to `under_review`

## 5. Provider or admin updates review status

`PATCH /cabinet-requests/:requestId/review-status`

Headers:

- `Authorization: Bearer <provider_token>` or `<admin_token>`
- `Content-Type: application/json`

Body for review start:

```json
{
  "status": "under_review"
}
```

Body for site visit pending:

```json
{
  "status": "site_visit_pending",
  "visitNotes": "Will call customer today to confirm measurement visit."
}
```

Body for rejection:

```json
{
  "status": "rejected",
  "reason": "Outside service area."
}
```

## 6. Provider or admin sends quote

`PATCH /cabinet-requests/:requestId/quote`

Headers:

- `Authorization: Bearer <provider_token>` or `<admin_token>`
- `Content-Type: application/json`

Body:

```json
{
  "amountCents": 850000,
  "currency": "CAD",
  "scopeNote": "Includes cabinet build, soft-close hinges, and installation.",
  "visitNotes": "Measured on site and confirmed final layout."
}
```

Expected:

- request status becomes `quoted`

## 7. Customer gets request detail

`GET /cabinet-requests/:requestId`

Headers:

- `Authorization: Bearer <customer_token>`

Expected:

- quote data is visible
- customer can see current status

## 8. Customer accepts quote and converts to booking

`POST /cabinet-requests/:requestId/accept-quote`

Headers:

- `Authorization: Bearer <customer_token>`
- `Content-Type: application/json`

Body:

```json
{
  "scheduledAt": "2026-04-20T14:00:00.000Z"
}
```

Expected:

- request status becomes `converted`
- response returns both the updated request and the created booking
- created booking should be in `accepted` status so payment can start with the existing payment flow

## 9. Customer cancels request

This works only before terminal completion.

`POST /cabinet-requests/:requestId/cancel`

Headers:

- `Authorization: Bearer <customer_token>`
- `Content-Type: application/json`

Body:

```json
{
  "reason": "Not proceeding right now."
}
```

Expected:

- request status becomes `cancelled`

---

## 10. After accept-quote: save the booking id

`POST /cabinet-requests/:requestId/accept-quote` returns a normal **booking** in the same response.

Save for later calls:

- `bookingId` = `data.booking._id` from the JSON response (or `data.request.bookingId` on a later `GET /cabinet-requests/:requestId`).

In Postman, set an environment variable, for example:

- `{{BOOKING_ID}}` = that value.

From here on you use the **existing bookings + payments** APIs. The cabinet request itself is finished (`converted`); the job is tracked as a booking.

**Prerequisites for payment**

- Booking status must be `accepted` (cabinet conversion already does this).
- Provider must have a **Stripe Connect** `payout.accountId` on their `ProviderProfile` (same as normal bookings).
- `STRIPE_SECRET_KEY` and related Stripe env vars must be set on the server.

---

## 11. Customer: get booking detail

`GET /bookings/:bookingId`

Headers:

- `Authorization: Bearer <customer_token>`

Use this to confirm `status`, `paymentStatus`, `price`, and `scheduledAt` after payment or provider actions.

---

## 12. Public: Stripe publishable key (for mobile / test UI)

`GET /payments/config`

No auth.

Response includes `data.publishableKey` for the Stripe client SDK on the customer app.

---

## 13. Customer: create PaymentIntent

`POST /payments/intent`  
(alternate path: `POST /payments/intents`)

Headers:

- `Authorization: Bearer <customer_token>`
- `Content-Type: application/json`

Body:

```json
{
  "bookingId": "{{BOOKING_ID}}"
}
```

Optional (saved card):

```json
{
  "bookingId": "{{BOOKING_ID}}",
  "paymentMethodId": "pm_..."
}
```

Expected:

- status `200`
- `data.clientSecret` for Stripe SDK confirmation
- `data.paymentIntentId`

If you see errors:

- **Booking must be accepted before payment** — booking is not `accepted` (should not happen right after cabinet accept if conversion succeeded).
- **Provider payout account is not connected** — fix provider Stripe Connect in admin/provider profile before testing payment.

---

## 14. Customer: complete payment (Stripe)

Postman cannot fully “tap to pay” like the app. In production the **Flutter app** uses the `clientSecret` with Stripe SDK to confirm the payment.

After success, Stripe sends a webhook to your server:

- `POST /api/v1/payments/webhook` (configured in Stripe Dashboard; raw body required — already set up in `app.js`)

The webhook updates the booking to **paid** when `payment_intent.succeeded` fires.

For **Postman-only** testing without the mobile app, use section 16 (dev simulate) in non-production.

---

## 15. Provider: list bookings (optional check)

`GET /bookings/provider/me`

Headers:

- `Authorization: Bearer <provider_token>`

Query (optional):

- `tab=pending` | `active` | `completed` | `cancelled` | `all`

After the customer pays, the booking should move toward **paid** so the provider can start the job.

---

## 16. DEV ONLY: simulate paid without Stripe (admin)

**Only when `NODE_ENV` is not `production`.**

`POST /payments/dev/simulate-paid/:bookingId`

Headers:

- `Authorization: Bearer <admin_token>`

Example:

`POST /payments/dev/simulate-paid/{{BOOKING_ID}}`

Use this to mark the booking paid in the database when you are not running a full Stripe confirmation + webhook flow from Postman.

---

## 17. Provider: start job

`PATCH /bookings/:bookingId/start`

Headers:

- `Authorization: Bearer <provider_token>`

Rules in code:

- Booking must be **`paid`** before start.
- Caller must be the booking’s provider.

Expected:

- booking `status` becomes `in_progress`

---

## 18. Provider: complete job

`PATCH /bookings/:bookingId/complete`

Headers:

- `Authorization: Bearer <provider_token>`

Rules in code:

- Booking must be **`in_progress`**.
- Must be **paid**.

Expected:

- booking `status` becomes `completed`
- `insuranceStatus` typically becomes `active` per your booking model

---

## 19. Optional: cancel booking

Customer or provider can cancel per existing rules.

`PATCH /bookings/:bookingId/cancel`

Headers:

- `Authorization: Bearer <customer_token>` or `<provider_token>`
- `Content-Type: application/json`

Body (optional reason):

```json
{
  "reason": "Changed plans."
}
```

---

## End-to-end order (cabinet → money → job done)

1. Customer: create cabinet request → admin assigns provider → review → quote → customer **accept-quote** → get `BOOKING_ID`.
2. Customer: `POST /payments/intent` → app pays with Stripe (or dev: admin **simulate-paid**).
3. Provider: `PATCH /bookings/:id/start` → `PATCH /bookings/:id/complete`.

## Status reference

- `submitted`
- `under_review`
- `site_visit_pending`
- `quoted`
- `accepted`
- `rejected`
- `cancelled`
- `converted`

Note:

In this implementation, customer quote acceptance immediately creates the booking, so the request quickly ends in `converted`. The request still stores `acceptedAt` before conversion for tracking.
