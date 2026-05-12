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
