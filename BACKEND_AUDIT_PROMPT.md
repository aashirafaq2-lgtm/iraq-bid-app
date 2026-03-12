# Comprehensive Backend Audit & Integration Master Prompt

**Role:** Senior Backend Engineer & System Architect
**Objective:** Perform a complete audit and integration check of the BidMaster specific backend. Ensure 100% alignment with the Flutter App and Admin Panel requirements. Fix any broken routes, missing fields, or logic errors.

---

## 🚀 Phase 1: Authentication & User Logic (CRITICAL)
**Goal:** Enforce strict separation of Login/Signup and support new profile fields.

1.  **Strict Login Flow (`/auth/login-phone`):**
    *   **Logic:** MUST check if `phone` exists in DB.
    *   **Condition:** If phone does NOT exist -> Return `404 Not Found` ("User not registered. Please sign up.").
    *   **Action:** DO NOT send OTP for non-existent users on login route.

2.  **Expanded Signup Flow (`/auth/register`):**
    *   **New Fields:** Update `User` model to accept `city` (string) and `area` (string).
    *   **Logic:** Check if `phone` already exists. If yes -> Return `400 Bad Request` ("User already exists").
    *   **Payload:** Accept `{ name, phone, role, city, area, referral_code }`.
    *   **Referral:** Verify `referral_code` validity if provided.

3.  **Profile Update:**
    *   Ensure `update-profile` endpoint accepts changes to `city` and `area`.

---

## 🛍️ Phase 2: Product & Home Screen Integration
**Goal:** Ensure data feeds for sliders and categories are accurate.

1.  **Banners (`/banners`):**
    *   Ensure endpoint returns valid image URLs (handle full paths vs relative paths).
    *   Verify empty state returns `[]` JSON, not error.

2.  **Categories (`/categories`):**
    *   Return list of active categories.
    *   Ensure no duplicates.

3.  **Product Feeds (Separation of Concerns):**
    *   **Company Products:** `GET /products/company` -> Must ONLY return admin-uploaded products.
    *   **Seller Products:** `GET /products/seller` -> Must ONLY return products with `role: 'seller_products'` AND `status: 'approved'`.
    *   **Search/Filter:** Verify partial text search works for both endpoints.

---

## 🔨 Phase 3: Bidding & Auction Engine
**Goal:** Real-time accuracy and privacy.

1.  **Placing a Bid (`POST /bid/place`):**
    *   **Validation:** Bid amount > Current Highest Bid.
    *   **Validation:** Auction time has NOT ended.
    *   **Logic:** Update `current_bid`, `bids_count`, and `last_bidder_id`.

2.  **Auction Timer:**
    *   Server-side validation: If `endTime` passed, reject new bids.
    *   **Auto-End:** (Optional) Cron job or trigger to mark expired auctions as `ended`.

3.  **Privacy (API Level):**
    *   *Note:* Frontend hides names ("Seller", "Bidder"), but Backend should ensure it doesn't send sensitive PII (Personal Identifiable Information) like email/phone in public product lists.

---

## 📦 Phase 4: Seller Dashboard (App Side)
1.  **Create Product:**
    *   Endpoint: `POST /products/create`
    *   **Default Status:** Must set `status: 'pending'` automatically for Seller roles.
    *   **Image Upload:** Verify multipart/form-data handles multiple images correctly.
    *   **Compression:** Ensure backend handles compressed images (JPG/PNG) correctly and generates appropriate thumbnails.

2.  **My Products:**
    *   Endpoint: `GET /products/my-products`
    *   Return ALL statuses (Pending, Approved, Rejected, Ended) for the logged-in seller.

---

## 🛡️ Phase 5: Admin Panel Integration
1.  **Product Approval:**
    *   Endpoint: `PUT /admin/products/{id}/approve` or `reject`.
    *   Logic: Changing status updates visibility in the Main App's "Seller Products" list immediately.

2.  **User Management:**
    *   Ability to block/ban users (prevent login).

---

## ⚡ Phase 6: Real-time Bidding (Socket.io)
**Goal:** Implement WebSocket events for instant updates.

1.  **Rooms:** Implement product-specific rooms (`product_{id}`).
2.  **Events:**
    *   `join_room`: Client joins when opening product details.
    *   `leave_room`: Client leaves when closing product details.
    *   `bid_updated`: Broadcast this event to everyone in the room when a new bid is successfully placed.
    *   **Payload:** `{ "productId": "id", "currentBid": 500, "totalBids": 12, "lastBidder": "User X" }`.

---

## 🔔 Phase 7: Push Notifications (OneSignal)
**Goal:** Integrate OneSignal for Iraq-compatible notifications.

1.  **External User ID:** Map OneSignal `external_id` to the database `userId`.
2.  **Triggers:**
    *   **Outbid:** Notify previous bidder when someone places a higher bid.
    *   **Auction End:** Notify winner and seller when auction finishes.
    *   **Product Approval:** Notify seller when admin approves their product.
3.  **Data Payload:** Ensure notification click carries `productId` for deep linking in the app.

---

## 📊 Phase 8: Seller Analytics & Advanced Stats
**Goal:** Provide data for the new Analytics Dashboard.

1.  **Endpoint:** `GET /seller/analytics`
2.  **Fields Required:**
    *   `totalSales`: Total revenue from ended auctions.
    *   `activeBids`: Current number of ongoing bids by the seller.
    *   `biddingActivity`: Data array for bar chart (Bids vs Date).
    *   `revenueData`: Data array for line chart (Revenue vs Date).
    *   `successRate`: Percentage of approved products that resulted in a sale.

---

## ✅ Phase 9: API Route Audit Checklist
*Please verify every single route below triggers correctly:*

*   [ ] `POST /auth/login-phone` (Strict Check)
*   [ ] `POST /auth/verify-otp`
*   [ ] `POST /auth/register` (With City/Area)
*   [ ] `GET /products/company`
*   [ ] `GET /products/seller` (Approved only)
*   [ ] `GET /products/{id}` (Details)
*   [ ] `POST /bid/{id}`
*   [ ] `GET /notifications/unread-count`
*   [ ] `POST /products/upload` (Image handling)
*   [ ] `WS /socket.io` (Real-time connection)
*   [ ] `GET /seller/analytics` (Dashboard data)
*   [ ] `POST /notifications/onesignal-sync` (Sync OneSignal ID)

**Action Required:**
Please run this audit, update the Codebase/Database schema for `city/area`, and fix any logic where "Seller Products" might be mixing with "Company Products" or where Login allows unregistered users.
