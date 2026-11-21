# 🍲 FoodBridge (अन्नसेतू)
### Real-Time Surplus Food & Essentials Redistribution Network

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Realtime_WebSockets-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Tests](https://img.shields.io/badge/Tests-145%2F145_Passing-10B981?logo=checkmarx&logoColor=white)](https://github.com/codewithyogeshh/Update_FoodBridge)
[![Code Quality](https://img.shields.io/badge/flutter_analyze-0_Issues-success)](https://github.com/codewithyogeshh/Update_FoodBridge)
[![WCAG](https://img.shields.io/badge/Accessibility-WCAG_2.1_AA-blue)](https://www.w3.org/WAI/standards-guidelines/wcag/)
[![License](https://img.shields.io/badge/License-MIT-amber.svg)](LICENSE)

> **"Share More. Waste Less. Bridge the Need."**  
> **FoodBridge** is an end-to-end, real-time cross-platform ecosystem designed to eliminate hyper-local food waste by instantaneously connecting Surplus Donors (Hotels, Caterers, Households) with Verified Shelters/NGOs, Dedicated Couriers, and Central System Administrators.

> **🔗 Live demo:** [https://foodbridge-live-demo-thmc5n.freebuff.site](https://foodbridge-live-demo-thmc5n.freebuff.site) &nbsp;·&nbsp; **📦 Source:** [github.com/codewithyogeshh/Update_FoodBridge](https://github.com/codewithyogeshh/Update_FoodBridge)

> ℹ️ The live link is an interactive browser demo of the same four role flows (Donor, NGO Shelter, Volunteer Courier, Super Admin), built for one-click evaluation. It runs on **simulated data** in the browser; the Flutter app in this repository is the real implementation backed by Supabase.

---

## 📱 Visual Showcase & Application Screenshots

<div align="center">
  <table>
    <tr>
      <td align="center" width="25%">
        <b>Volunteer Dispatch Console</b><br>
        <i>(10/10 Midnight Dark Mode)</i><br><br>
        <img src="docs/screenshots/volunteer_dashboard_dark.png" width="220" alt="Volunteer Dashboard Dark Mode" />
      </td>
      <td align="center" width="25%">
        <b>Super Admin Live Console</b><br>
        <i>(Multi-Device Real-time Mesh)</i><br><br>
        <img src="docs/screenshots/admin_console_live.png" width="220" alt="Admin Console Live" />
      </td>
      <td align="center" width="25%">
        <b>Donation Tracking & Dispatch</b><br>
        <i>(Lifecycle & Dual-OTP Chain)</i><br><br>
        <img src="docs/screenshots/donation_detail.png" width="220" alt="Donation Details Screen" />
      </td>
      <td align="center" width="25%">
        <b>User Profile & Settings</b><br>
        <i>(Dynamic Avatar & Sync)</i><br><br>
        <img src="docs/screenshots/user_profile.png" width="220" alt="User Profile Screen" />
      </td>
    </tr>
  </table>
</div>

---

## 🌟 Key Platform Capabilities

### 1. 🔄 Multi-Device Sub-100ms Real-Time Synchronization
* **Supabase WebSocket Mesh (`public:donations_realtime`):** When a donor publishes or updates a donation, a sub-100ms `donation_sync` event triggers instant re-renders across all active peer nodes.
* **Peer-to-Peer State Recovery:** Offline nodes seamlessly catch up on active state upon reconnection through coordinated `peer_request_sync` and `peer_response_sync` protocols.

### 2. 🔐 Dual-OTP Cryptographic Custody Protocol
* **Pickup Authentication:** 4-digit PIN generated for the Donor; Volunteer courier must enter this physical PIN to transition order status from `claimed` $\rightarrow$ `in_transit`.
* **Delivery Authentication:** 4-digit PIN or dynamic QR Code generated for the Shelter NGO; required to transition status from `in_transit` $\rightarrow$ `distributed`.
* **Zero Ghost Deliveries:** Impossible for courier or shelter to falsely claim completion without physical proximity and code exchange.

### 3. 🍱 Dual-Stream Redistribution Architecture
* **Surplus Prepared Food:** Food category tags (Veg/Non-Veg), prep timestamp, holding temperature (`Hot-Holding >63°C`, `Ambient`, `Chilled <5°C`), allergen declarations, and collection deadlines.
* **Clean Wearable Essentials:** Clothes category, condition grading (`Brand New`, `Like New`, `Gently Used`), target group (`Kids`, `Adults`), and packaging photo.

### 4. 🎨 10/10 Realtime Colors 60-30-10 Design System
* **Adaptive Dark & Light Themes:** Rich Midnight Obsidian (`#0B0F17`) base for OLED battery saving paired with crisp high-contrast light mode.
* **Touch & Haptic Fluidity:** 100% compliant with Apple Human Interface Guidelines and Emil Kowalski motion primitives; 48x48dp minimum touch targets.
* **Full Marathi & English Localization:** Instant switch between मराठी and English across all screens.

---

## 🏛️ System Architecture

FoodBridge enforces strict **Clean Architecture** with a Feature-First modular structure:

```
lib/
├── core/
│   ├── config/              # Environment configurations & Supabase client
│   ├── localization/        # App translations (English & Marathi dictionaries)
│   ├── services/            # AI Advisory, Media, Location, Email & Offline Sync
│   ├── theme/               # Realtime Colors 60-30-10 Token System & Typography
│   └── widgets/             # Reusable UI components (FBTextField, FBButton, ExitDialog)
└── features/
    ├── admin/               # Super Admin verification, metrics, user management
    ├── authentication/      # Multi-role Auth, 6-digit OTP verification, Sessions
    ├── donations/           # Core lifecycle state machine, real-time sync engine
    ├── donor/               # Surplus food & clothing donation creation forms
    ├── ngo/                 # Shelter discovery feed, claims, capacity checking
    ├── notifications/       # Real-time in-app notification center
    ├── profile/             # Profile editing, avatar upload, transport switcher
    └── volunteer/           # Courier dispatch, GPS navigation, OTP validation
```

---

## 🧪 Rigorous Quality Assurance & Test Metrics

FoodBridge has passed a comprehensive 145-point automated verification suite with **zero regressions and zero analyzer warnings**:

```bash
$ flutter analyze
Analyzing Food-Bridge-updated...
No issues found! (ran in 6.4s)

$ flutter test
01:09 +145: All tests passed!
```

### Verified Test Suites:
- `test/core/services/ai_service_test.dart` (14/14 tests passed)
- `test/features/donations/multi_device_sync_test.dart` (3/3 tests passed)
- `test/features/admin/admin_user_sync_test.dart` (3/3 tests passed)
- `test/features/security/security_permissions_test.dart` (12/12 tests passed)
- `test/features/volunteer/volunteer_delivery_journey_test.dart` (8/8 tests passed)
- `test/features/accessibility/accessibility_and_contrast_test.dart` (WCAG AAA/AA passed)

---

## 🚀 Quick Start & Installation

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`v3.24.0` or higher)
- Android Studio / VS Code with Dart & Flutter extensions
- Android Device or Emulator (Android 10+ recommended)

### 1. Clone the Repository
```bash
git clone https://github.com/codewithyogeshh/Update_FoodBridge.git
cd Update_FoodBridge
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Static Analysis & Tests
```bash
flutter analyze
flutter test
```

### 4. Launch on Device / Emulator
```bash
flutter run
```

---

## 🔑 Quick Demo Credentials (1-Tap Login)

The login screen includes dedicated **1-Tap Quick Profile Chips** for effortless evaluation:

| Role | Demo Email | Password | Primary Interface |
| :--- | :--- | :--- | :--- |
| **Donor** | `donor@foodbridge.org` | `Password123!` | `/donor` |
| **Shelter NGO** | `ngo@foodbridge.org` | `Password123!` | `/ngo` |
| **Volunteer Courier** | `volunteer@foodbridge.org` | `Password123!` | `/volunteer` |
| **Super Admin** | `admin@foodbridge.org` | `Password123!` | `/admin` |

---

## 👥 Engineering Team & Academic Attribution

**Academic Project (Phase-1 & Final Implementation)**  
**Department of Computer Science & Engineering**  
*Karmaveer Bhaurao Patil College of Engineering, Satara (Affiliated to DBATU, Lonere)*

* **Project Guide:** Prof. Uma Bhokare

* **Team Members:**
  1. **Yogesh Gurunath Chavan** (PRN: `24062701242502`) — Lead Full-Stack & Flutter Engineer
  2. **Samruddhi Pramod Sawant** (PRN: `23062701242039`) — Quality Assurance & Research
  3. **Omkar Nilesh Shinde** (PRN: `23062701242121`) — Backend Integration & System Design
  4. **Shivraj Rajendra Yadav** (PRN: `23062701242102`) — UI/UX Engineering & Data Architecture

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
