# Campus Store POS - IT415 Practical Exam

A simple Flutter touchscreen POS kiosk implementing the required IT415 transaction flow.

## Run
1. Install Flutter SDK.
2. Open this folder in VS Code/Android Studio.
3. Run `flutter pub get`.
4. Run `flutter run -d chrome` for a landscape kiosk demo, or choose another Flutter device.

## Implemented acceptance cases
- Touch-oriented layout with large product cards and controls.
- Six products with prices; tap to add.
- Increase/decrease/remove cart items; automatic subtotals and total.
- Order review with Back preserving cart state.
- Cash, simulated QR, and simulated Credit/Debit Card payments.
- Cash validation rejects insufficient values; exact payment works; change calculated automatically.
- Payment Successful screen with unique transaction reference.
- Digital receipt with products, quantities, unit prices, subtotals, total, method, amount paid, change, date, status.
- New Transaction clears cart/payment/receipt state.
- SnackBar feedback for important actions.

## Instructor test example
Coffee x2 + Sandwich x1 + Soft Drink x1 = ₱175.00. Remove Soft Drink = ₱140.00. Cash ₱100 is rejected; Cash ₱200 on ₱140 produces ₱60 change.

## Storage choice
Product data is hard-coded because the exam permits hard-coded product data and no database is required for the core kiosk flow.
