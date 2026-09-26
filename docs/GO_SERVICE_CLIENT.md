# GO Partner service marketplace

Feature-branch UI for F-Backend PR #8 and Go-customer PR #7. No production deployment, live charge, payment credential change or gateway enablement.

The existing PartnerOrdersBoard public constructor and home/order section placement are retained. Courier accounts use the original board unchanged. Professional accounts check `/go-services/capabilities`; an old-backend 404/missing schema retains the original board in legacy_partner_orders_board.dart. Network and authorization failures do not fabricate jobs. Legacy requests remain accessible from the same area when the new board is available.

New jobs, current assignments and history use the matching server scopes with pagination. Partners see the job description/photos/area and submit an exact-decimal final labour quote with scope, materials, arrival and duration. Quoting does not modify wallet balances. The UI displays the server-returned commission, waits for customer selection, blocks starting an unpaid online booking, and requests customer completion rather than completing on the customer's behalf. Cancellation before work and disputes after work follow server rules. On return/balance changes the profile is refreshed.

The server owns authentication, geographic eligibility, one-winner assignment, quote expiration and all financial effects. Invited partners do not receive exact customer address or phone before agreement. Foreground list/detail polling is 15/10 seconds and stops when app lifecycle leaves foreground. This is not a claim of new push/deep-link handling. Old controllers are retained for legacy requests; staged performance should be monitored.

Tests cover transport contract, money, expiry, account-scope headers, capability fallback, selection ownership and quote/fulfillment controls. CI analyzes and compiles a web build without deployment. Staging end-to-end across both apps, device push navigation, old/new server compatibility and financial reconciliation are still required before rollout. Backend capability flags remain operator-controlled.
