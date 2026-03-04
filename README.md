<div align="center">

# 🏦 TempWal

### *The Only Wallet You Need*

**TempWal** is a smart, temporary-wallet payment platform that lets you create named wallets, generate QR codes with time or amount limits, collect payments from multiple people, and auto-transfer funds back to your main account — all in one seamless experience.

[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.2-02569B?logo=flutter)](https://flutter.dev)
[![React](https://img.shields.io/badge/React-18-61DAFB?logo=react)](https://reactjs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript)](https://www.typescriptlang.org)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%2B%20Auth-FFCA28?logo=firebase)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## 📖 Table of Contents

- [What is TempWal?](#-what-is-tempwal)
- [Key Features](#-key-features)
- [Use Cases](#-use-cases)
- [App Architecture](#-app-architecture)
- [Screens & Components](#-screens--components)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
  - [Flutter (Mobile)](#flutter-mobile-app)
  - [Web (React)](#web-react-app)
- [How It Works](#-how-it-works)
- [Project Structure](#-project-structure)
- [Contributing](#-contributing)

---

## 💡 What is TempWal?

TempWal is a **temporary wallet payment app** designed for situations where you need to collect money from multiple people under controlled conditions — like a fundraiser, an emergency drive, or a group collection. Instead of sharing your permanent account details, you create a **named temporary wallet**, generate a **smart QR code** with a time or amount limit, share it, and watch funds roll in. When the goal is hit or the timer runs out, everything **auto-transfers** to your main account.

TempWal ships as **two apps from the same codebase concept**:

| Platform | Location | Runtime |
|---|---|---|
| 📱 **Flutter Mobile App** | `/flutter` | Android · iOS · Windows |
| 🌐 **React Web App** | `/app` | Any modern browser |

---

## ✨ Key Features

### 💼 Multi-Wallet Management
- Create **unlimited named temporary wallets** (e.g., "Emergency Fund", "Disaster Relief", "Medical Help")
- Each wallet is independently managed with its own balance and transaction history
- Wallets can be **deleted safely** — any remaining balance is automatically transferred before deletion
- Expired wallets are kept in a read-only archive for historical reference

### 🔳 Smart QR Code Generation
- Generate a unique **payment QR code** linked to a specific temporary wallet
- Choose between two expiry modes:
  - ⏱ **Time Limit** — QR expires after 1–60 minutes; great for live events
  - 💰 **Amount Limit** — QR accepts payments until a target amount is reached ($10–$1,000)
- The **wallet name** is branded directly onto the QR code as a watermark
- Only one active QR can exist at a time per session, ensuring focused collection

### 📲 Multi-Person QR Scanning
- **Multiple people** can scan the same QR code and pay different amounts
- Real-time progress bar shows how much has been collected vs. the target
- Built-in **QR Scanner** lets users pay into someone else's active QR from their own main balance

### ⚡ Automatic Fund Transfer
- When a **time limit expires** or an **amount limit is reached**, all accumulated funds are instantly and automatically transferred to your main account
- Manual **"Transfer Now"** button available at any time to move funds early
- Full audit trail of every transfer with timestamps and amounts

### 📜 Transaction History
- Complete log of every transaction:
  - 📥 **Received** — incoming payments from QR scans
  - 📤 **Sent** — outgoing payments you made by scanning someone else's QR
  - 🔀 **Transferred** — manual wallet-to-account transfers
  - 🤖 **Auto-Transferred** — automatic transfers triggered by limit conditions
  - ❌ **Failed** — declined or expired QR attempts
- Per-wallet transaction drill-down view

### 🌗 Dark & Light Mode
- Fully themed UI with smooth transitions
- Light mode: elegant purple-to-blue gradient palette
- Dark mode: polished dark zinc palette with vibrant yellow accents
- Preference is **persisted** between sessions

### 🔐 Security & Authentication *(Flutter)*
- **Firebase Authentication** — email/password sign-up and sign-in
- Optional **4-digit Transaction PIN** for an extra layer of protection
- Secure sign-out with full local state cleanup

### 🔊 Voice & Sound Feedback *(Flutter)*
- **Text-to-speech** voice announces every received payment (e.g., *"Credited 500 rupees from Ravi"*)
- Audio chime plays on successful payment completion
- Both features can be toggled individually in Settings

### 🔥 Real-Time Firebase Sync *(Flutter)*
- QR payments are processed via **Cloud Firestore** in real time
- The receiver's device instantly reflects incoming payments without any manual refresh
- Sender's balance is deducted and synced to their Firestore document atomically

### 💾 Offline Persistence *(Flutter)*
- All wallet data, active QR state, and transaction history are cached locally via **SharedPreferences**
- App is fully usable offline with a graceful Firebase fallback

### 🎭 Payment Simulator *(Web)*
- Demo mode built into the Active QR screen
- Simulate incoming payments in increments ($10, $25, $50, $100 or custom) for testing and presentations

### 🖼 Profile Management *(Flutter)*
- Pick a profile picture from your device gallery
- Displays your name and email in the Settings screen

---

## 🎯 Use Cases

| Scenario | How TempWal Helps |
|---|---|
| 🚨 **Emergency Fundraising** | Create an "Emergency Fund" wallet, share the time-limited QR on social media, collect from anyone instantly |
| 🌊 **Disaster Relief Drives** | Name a wallet "Flood Relief", set an amount target, let multiple donors scan and contribute |
| 🏥 **Medical Bill Collection** | Create a wallet with an exact amount limit matching the bill — closes automatically when the goal is met |
| 🎉 **Group Event Payments** | Collect money for a birthday dinner, office party, or trip without sharing personal UPI or bank details |
| 🛒 **Temporary Vendor Stall** | Use a time-limited QR at a fair or pop-up market — QR auto-expires when your stall closes |
| 🎓 **Education & Community Funds** | Set up named wallets for specific causes and share the QR in community chats or notice boards |
| 🧪 **Fintech Demos & Prototypes** | Use the built-in Payment Simulator to demonstrate real-time QR payment flows without real money |

---

## 🏗 App Architecture

```
TempWal
├── Flutter Mobile App (Production-ready)
│   ├── Firebase Auth         → User authentication
│   ├── Cloud Firestore       → Real-time payment processing & user data
│   ├── AppState (Provider)   → Central state management
│   ├── SharedPreferences     → Local caching / offline support
│   ├── QR Flutter            → QR code rendering
│   ├── Mobile Scanner        → QR code scanning via device camera
│   ├── Flutter TTS           → Voice payment announcements
│   └── Audioplayers          → Payment success sound
│
└── React Web App (Prototype / Demo)
    ├── React + TypeScript    → UI & business logic
    ├── react-qr-code         → QR code rendering
    ├── Tailwind CSS          → Styling
    ├── shadcn/ui             → UI component library
    └── In-memory state       → No backend required for demo
```

### State Flow (Flutter)

```
User Action
    │
    ▼
AppState (ChangeNotifier)
    ├── Updates local state
    ├── Persists to SharedPreferences
    ├── Syncs with Firestore (when online)
    └── notifyListeners() → UI rebuilds
```

---

## 📱 Screens & Components

| Screen | Description |
|---|---|
| **Auth Screen** | Email/password sign-in and sign-up backed by Firebase Auth |
| **Dashboard** | Main overview: main account balance, all temporary wallets, quick action buttons |
| **Generate QR** | Select a wallet, choose limit type (time/amount), set value, generate QR |
| **Active QR** | Display live QR code with countdown or progress bar, payment simulator, share & transfer controls |
| **Scanner** | Scan (or select) an active QR, enter amount, pay from main balance |
| **Transaction History** | Full chronological transaction log with type, status, and amount |
| **Wallet Transactions** | Per-wallet transaction drill-down with embedded active QR panel |
| **Manage Wallets** | Add new wallets (with suggested names), view balances, delete wallets |
| **Settings** | Dark mode toggle, payment voice toggle, transaction PIN, profile picture, sign-out |

---

## 🛠 Tech Stack

### Flutter Mobile App

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | UI framework |
| `provider` | ^6.1.1 | State management |
| `firebase_core` | ^3.1.1 | Firebase initialization |
| `firebase_auth` | ^5.1.1 | User authentication |
| `cloud_firestore` | ^5.0.2 | Real-time database & payment sync |
| `qr_flutter` | ^4.1.0 | QR code generation |
| `mobile_scanner` | ^5.1.0 | Camera QR scanner |
| `flutter_tts` | ^4.0.2 | Text-to-speech voice alerts |
| `audioplayers` | ^5.2.1 | Payment success audio |
| `shared_preferences` | ^2.2.2 | Local persistence / offline cache |
| `image_picker` | ^1.0.7 | Profile picture selection |
| `path_provider` | ^2.1.2 | Local file storage |
| `intl` | ^0.19.0 | Date/number formatting |

### React Web App

| Technology | Purpose |
|---|---|
| React 18 + TypeScript | Component framework & type safety |
| Tailwind CSS | Utility-first styling |
| shadcn/ui | Accessible UI component library |
| react-qr-code | QR code rendering |
| lucide-react | Icon set |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.2.0 (for mobile app)
- **Node.js** ≥ 18 (for web app)
- A **Firebase project** with Firestore and Authentication enabled (for Flutter)
- Android Studio or Xcode (for running on a physical device / emulator)

---

### Flutter Mobile App

```bash
# 1. Navigate to the flutter directory
cd flutter

# 2. Install dependencies
flutter pub get

# 3. Add your Firebase config
#    - Download google-services.json from Firebase Console
#    - Place it at: flutter/android/app/google-services.json
#    - (For iOS) Download GoogleService-Info.plist → flutter/ios/Runner/

# 4. Run on a connected device or emulator
flutter run

# Optional: Build a release APK
flutter build apk --release
```

> **Tip:** If you're running for the first time after a Flutter SDK update, run `flutter clean && flutter pub get` first.

---

### Web React App

The web app is a self-contained React prototype with no build setup included in this repo. To run it:

```bash
# From the repo root, if you have a bundler configured:
# Install dependencies (adjust based on your package manager setup)
npm install

# Start the development server
npm run dev
```

> The web app uses in-memory state — no Firebase setup is required. It is ideal for demos and design iteration.

---

## 🔄 How It Works

### Step-by-Step Payment Flow

```
1. SETUP
   └── Create a temporary wallet  →  give it a meaningful name
                                      (e.g., "Flood Relief")

2. GENERATE
   └── Select the wallet  →  choose a limit
       ├── ⏱ Time Limit: QR expires in N minutes
       └── 💰 Amount Limit: QR accepts until $X is collected

3. SHARE
   └── Share the QR code  →  anyone with TempWal or a QR scanner can pay
       └── Multiple people scan → payments accumulate in the wallet

4. COLLECT (Real-time)
   └── Each payment:
       ├── Deducts from the sender's main account
       ├── Credits the temporary wallet
       ├── Logs a transaction on both sides
       └── Updates the progress bar in real time

5. AUTO-TRANSFER
   └── When limit is reached:
       ├── All wallet funds transfer to your main account
       ├── Voice alert plays: "500 rupees auto transferred"
       └── QR is marked expired and archived
```

### QR Limit Types Explained

| Limit Type | Behaviour | Best For |
|---|---|---|
| **Time** (1–60 min) | QR closes after the timer; whatever was collected transfers | Live events, stalls, limited-time drives |
| **Amount** ($10–$1000) | QR closes the moment the target is reached; exact-goal fundraising | Medical bills, specific purchases, goal-based campaigns |

---

## 📁 Project Structure

```
TempWal/
│
├── app/                          # React Web App
│   ├── App.tsx                   # Root component, global state & view router
│   └── components/
│       ├── Dashboard.tsx         # Home screen with balances & wallet list
│       ├── GenerateQR.tsx        # QR configuration & generation
│       ├── ActiveQR.tsx          # Live QR display with timer/progress
│       ├── Scanner.tsx           # QR scanner & payment submission
│       ├── ManageWallets.tsx     # Wallet CRUD interface
│       ├── TransactionHistory.tsx# Full transaction log
│       ├── WalletTransactions.tsx# Per-wallet transaction view
│       └── ui/                   # shadcn/ui component library
│
├── flutter/                      # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart             # App entry, theme, shell & navigation
│   │   ├── app_state.dart        # Central state (ChangeNotifier + Firebase)
│   │   ├── models/
│   │   │   └── models.dart       # TempWallet, WalletTransaction, ActiveQRData
│   │   ├── screens/
│   │   │   ├── auth_screen.dart
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── generate_qr_screen.dart
│   │   │   ├── active_qr_screen.dart
│   │   │   ├── scanner_screen.dart
│   │   │   ├── manage_wallets_screen.dart
│   │   │   ├── wallet_transactions_screen.dart
│   │   │   ├── transaction_history_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── utils/
│   │       └── formatters.dart   # Currency / date helpers
│   ├── assets/
│   │   ├── app_icon.png
│   │   └── sounds/
│   │       └── payment_success.mp3
│   └── pubspec.yaml
│
├── styles/                       # Global CSS for web
│   ├── index.css
│   ├── tailwind.css
│   └── theme.css
│
└── LICENSE
```

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

Please keep PRs focused and include a clear description of what changed and why.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with ❤️ by [Judethedude007](https://github.com/Judethedude007)

*TempWal — collect money smartly, transfer automatically.*

</div>
