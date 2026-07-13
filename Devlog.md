# 🪙 MaidPocket

A minimalist, reliable, and cute personal finance manager built with Flutter. Designed to be lightweight and efficient, focusing on seamless user experience and local data security.

## 🛠️ Tech Stack
* **Framework:** [Flutter](https://flutter.dev/)
* **Database:** [SQFlite](https://pub.dev/packages/sqflite) (with FFI for desktop/Project IDX support)
* **Build Tool:** Project IDX / Flutter CLI
* **Version Control:** Git & GitHub

---

## 📝 Devlog: The Journey So Far

### **Phase 1: Foundation & Infrastructure**
* Initialized the Flutter project with a clean architecture in mind.
* Set up **SQFlite** for local data persistence.
* Implemented **FFI (Foreign Function Interface)** initialization to ensure database compatibility within the Project IDX Linux environment.

### **Phase 2: Visual Identity & Branding**
* Designed a custom application logo representing the "Maid" theme.
* Configured `flutter_launcher_icons` to automate icon generation for various screen densities.
* Organized the project assets directory (`assets/icons/`) for better maintainability.

---

## 🚧 The "Wall of Errors" (Troubleshooting)

Every project has its hurdles. Here are the technical challenges faced and resolved during development:

### 1. **The Syntax Ghost (Bracket Mismatch)**
* **Error:** `lib/main.dart:20:1: Error: Expected a declaration, but got '}'.`
* **Cause:** Improper nesting during code refactoring led to an extra closing brace.
* **Resolution:** Audited the `main.dart` structure and removed the redundant declaration.

### 2. **Icon Tree Shaking Failure**
* **Error:** `Target aot_android_asset_bundle failed: Error: Avoid non-constant invocations of IconData.`
* **Cause:** Flutter's release compiler attempted to tree-shake icons that were being called dynamically from the database.
* **Resolution:** Used the `--no-tree-shake-icons` flag during the release build to preserve the icon font set.

### 3. **The Git Synchronization Conflict**
* **Error:** `[rejected] main -> main (fetch first)`.
* **Cause:** Divergent histories created by adding a README/LICENSE directly on GitHub web without pulling locally first.
* **Resolution:** Performed a `git pull origin main --rebase` to integrate remote changes smoothly before pushing local commits.

### 4. **The Great Download Odyssey**
* **Issue:** Difficulty retrieving the `.apk` file from the cloud environment due to server-side restrictions and expired SSL certificates on third-party sharing sites.
* **Attempted Solutions:** Tried `transfer.sh`, `file.io`, `catbox.moe`, and `python3 http.server`.
* **Ultimate Fix:** Forced the release APK into version control (`git add -f`) for direct retrieval via the GitHub repository.

---

## 🚀 Roadmap & Future Plans
* [ ] **UI Overhaul:** Implementing a "Premium Minimalist" design language.
* [ ] **Analytics:** Adding charts and spending summaries.
* [ ] **Categories:** Customizable categories for better financial tracking.
* [ ] **Export:** Feature to export data to CSV/PDF.

---

*“Uhee~ Work hard, sleep harder.”*

# 🚀 Devlog: MaidPocket v1.2.0 - The Aesthetic & Stability Update

Uhee~ After a long survival night debugging on a 4GB RAM laptop, MaidPocket officially upgraded with premium UI adjustments, dynamic theme logic, and solid structural bugfixes!

## ✨ What's New

### 🎨 Visual & UI Enhancements
- **Modernized Drawer:** Ditched the outdated Google-blue style. The sidebar now adopts a clean glassmorphism layout that responds correctly to both Light and Dark modes.
- **Neon Bright Dark Mode:** Enhanced wallet visibility in dark mode with saturated neon gradients and subtle borders so your wallet card doesn't fade into the dark background.
- **Visual Dividers:** Added structural divider lines to clearly separate the wallet slider from the transaction history section.

### 🎭 Mood & Theme Systems (4-Stage Adaptation)
- **Dynamic Limit Gradients:** All custom themes (**Sakura 🌸, Ocean 🌊, Autumn 🍂, Forest 🌲, and Amethyst 🔮**) now support full 4-stage color shifts based on your balance limits:
  - 😭 *Saldo Kering:* Desaturated/faded color tones.
  - ⚠️ *Saldo Menipis:* Darker/alert shades.
  - 🌿 *Saldo Aman:* Balanced aesthetic pastel gradients.
  - 👑 *Sultan Mode:* Full-blown vibrant neon highlights!
- **Dynamic Quotes & Icons:** The descriptive quote and indicator icon at the bottom of the wallet automatically updates alongside the 4 mood phases.

### 🔒 Privacy & Core Features
- **Optional Data Privacy Switch:** Changed the forced banking sensor into an optional toggle switch in the drawer settings. Users can choose to blur their balance (`Rp ••••••••`) by default or keep it visible.
- **Robust Transaction Deletion:** Implemented instant calculation rollbacks when removing records—available both via swipe-to-delete gestures and an explicit delete button inside the edit modal.

## 🐛 Bugfixes & Code Cleanups
- **Async Context Safety:** Fixed multiple `use_build_context_synchronously` warnings by embedding `if (!ctx.mounted) return;` safety guards before invoking `Navigator.pop()`.
- **Strict Linter Adherence:** Wrapped all single-line `if` condition flow controls inside proper curly braces `{}` to comply with strict Flutter layout formatting.
- **Deprecation Cleanups:** Swapped outdated `activeColor` parameter inside `Switch` widgets with the newer `activeThumbColor` implementation.
k