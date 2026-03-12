# Changelog - Bidmaster Flutter App

## Version 1.0.1 (Production Release)

### 🚀 Major Improvements
- **Persistent Bottom Navigation:** Added a stable, persistent bottom navigation bar using `ShellRoute`. Switching tabs (Home, Bids, Wishlist, Wins) no longer resets page state or hides the navigation bar.
- **Product Separation:** Implemented strict separation between "Company Products" and "Seller Products" (Marketplace).
  - Company Mode: Shows only company-listed items.
  - Seller Mode: Shows marketplace listings from other sellers.
- **Mobile Responsiveness:** Optimized product grid layouts across all screens (`Home`, `Wishlist`, `SellerDashboard`) by adjusting aspect ratios to prevent content clipping on smaller devices.

### 🐛 Bug Fixes
- **Seller Redirection:** Fixed navigation logic where Sellers were incorrectly redirected to role selection when accessing Wishlist and Wins.
- **Category Slider:** Fixed horizontal scrolling issue on mobile devices by enabling `ClampingScrollPhysics` for smooth drag gestures.
- **Taskbar Visibility:** Resolved issue where the bottom taskbar would disappear when navigating to certain screens.
- **Stack Stability:** Replaced `context.push()` with `context.go()` for main tab navigation to prevent infinite navigation stack buildup and improve app performance.

### 🔧 Technical Updates
- **API Integration:** Added dedicated API methods `getCompanyProducts()` and `getSellerProducts()` to standardise data fetching.
- **Router Configuration:** Refactored `AppRouter` to support `ShellRoute` for better navigation state management.
