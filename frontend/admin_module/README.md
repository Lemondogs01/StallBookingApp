# Admin Module (Frontend) – Campus Market Stall Booking, MFU

Sprint 2 deliverable: Admin screens in Flutter on **mock data**
(no front-back connection, per the project plan).

## Features
- Login (mock) / Logout
- Dashboard: stalls, pending requests, today's revenue, slips waiting to be checked
- Stalls: Create / Read / Update / Delete, search + zone filter
- Bookings: tabs by status; tap a request to check its payment slip, then approve or reject
- **Payments**: payment history (Awaiting check / Paid / Rejected / Refunded), PromptPay receiving account settings
- Revenue: daily / monthly summary, counting only verified (paid) bookings

## Payment flow (from the mfu_market_app prototype)
1. Vendor books a stall, pays by PromptPay QR and uploads the slip -> payment status `pending`
2. Admin opens the request, compares the slip with the amount and approves or rejects (with a reason)
3. Approve -> booking `approved`, payment `paid` (+ `paid_at`) and the amount counts as revenue
4. Reject -> booking `rejected`, payment `failed`
5. Vendor cancels a paid booking -> payment `refunded`

Maps to the `payments` table: id, booking_id, amount, payment_method, payment_status, paid_at, created_at.
The slip is a mock preview for now; Sprint 3 shows the image the vendor uploads.

## Run
```
flutter create .
flutter pub get
flutter run -d chrome
flutter test
```
