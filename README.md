# The Message Board Vault Hunt (CSC 4360 - Homework 02)

**Student Developer:** Mario Leonel Gutierrez Espinal  
**Course:** CSC 4360 – Mobile App Development  
**Assignment:** Homework 02 – The Message Board Vault Hunt  
**Focus:** Firebase Authentication · Cloud Firestore CRUD & Live Streams · Firestore Security Rules · Release Engineering  
**Platform Target:** Android (API 23+) & Flutter Multi-Platform  

---

## 🌟 Executive Summary

The **Message Board Vault Hunt** is a production-grade, real-time message board application built with Flutter, Firebase Authentication, and Cloud Firestore. The application demonstrates end-to-end cloud identity management, strict document authorization enforced at the database layer via Firestore Security Rules, and resilient live streaming of messages across devices.

Key highlights:
- **Styled Splash Screen:** Initialized before app launch with connection retry fallbacks.
- **Firebase Authentication & Centralized AuthService:** Clean email/password registration, login, and sign-out with auth-state stream routing.
- **Authoritative 5-Field Firestore User Record:** Stored under private path `users/{uid}` with `uid`, `firstName`, `lastName`, `role`, and `registrationDateTime` (server timestamp).
- **ProfileGate:** Prevents unprofiled access to the message board and handles "Auth success, Firestore write retry" scenarios cleanly without duplicate account creation.
- **Dedicated BoardService:** Full CRUD (Create, Read live stream, Update, Delete) behind typed methods; widgets never call Firestore directly.
- **Real-Time Live Streaming:** Board updates across all signed-in devices using `snapshots()` without manual refresh.
- **Strict Security Rules (`firestore.rules`):** Proves that authentication is separate from authorization; cross-user edits/deletes and forged UIDs are rejected with `permission-denied` by the database engine.
- **Extra Spices Implemented:**
  - **Main Spice (Required):** Release Readiness Gate — compiled and verified release APK (`build/app/outputs/flutter-apk/app-release.apk`) on Android with `<uses-permission android:name="android.permission.INTERNET" />`.
  - **Spice #4:** Idempotent Alchemist — deterministic document key and double-tap prevention ensuring exactly one message document under duplicate submits.
  - **Spice #5:** Schema Shape-shifter — versioned schema (`schemaVersion: 2`) with automated lossless migration for legacy v1 documents.
  - **Spice #6:** Batch Librarian — atomic `WriteBatch` deletion of user's own messages.

---

## 🗄️ Firestore Data Architecture & Placement

Professional Firebase architectures separate public broadcast content from private user records, giving every document and field an authoritative, deliberate writer:

| Document / Path | Fields & Types | Writer | Authorization Policy | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `users/{uid}` | `uid` (string), `firstName` (string), `lastName` (string), `role` (string), `registrationDateTime` (timestamp) | Client, once at registration (uid-keyed) | Owner only (`request.auth.uid == uid`). Immutability enforced on `uid` and `registrationDateTime`. | Private 5-field user profile record. |
| `users/{uid}/prefs/{doc}` | `optIn` (bool), `deviceToken` (string), `updatedAt` (timestamp) | Client / Callable | Owner only (`request.auth.uid == uid`). | Private user preferences and endpoints; never visible to other users. |
| `messages/{msgId}` | `authorUid` (string), `authorName` (string), `text` (string), `createdAt` (timestamp), `editedAt` (timestamp, optional), `schemaVersion` (int) | Authenticated author | Public read for signed-in users (`request.auth != null`). Create/update/delete restricted to `authorUid == request.auth.uid`. | Public board messages streamed live to all signed-in users. |

### Field Writers and Immutability Matrix
- **`messages/{msgId}.authorUid`**: Written once at creation from `request.auth.uid`. Immutable on update.
- **`messages/{msgId}.createdAt`**: Written once at creation via `FieldValue.serverTimestamp()`, validated with `request.resource.data.createdAt == request.time`.
- **`messages/{msgId}.editedAt`**: Written only on update via `FieldValue.serverTimestamp()`, validated with `request.resource.data.editedAt == request.time`.
- **`messages/{msgId}.text`**: Non-empty string (`size() > 0 && size() <= 5000`). Only text and editedAt may change during update.

---

## 🛡️ Security Rules Summary (`firestore.rules`)

The security rules enforce ownership and validation as an independent database security perimeter:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Default deny
    match /{document=**} {
      allow read, write: if false;
    }

    // Private user records (users/{uid})
    match /users/{uid} {
      allow read, delete: if isOwner(uid);
      allow create: if isOwner(uid) &&
                       request.resource.data.uid == uid &&
                       request.resource.data.registrationDateTime == request.time;
      allow update: if isOwner(uid) &&
                       request.resource.data.uid == resource.data.uid &&
                       request.resource.data.registrationDateTime == resource.data.registrationDateTime;

      match /prefs/{doc} {
        allow read, write: if isOwner(uid);
      }
      match /{subcollection}/{doc} {
        allow read, write: if isOwner(uid);
      }
    }

    // Public board messages (messages/{msgId})
    match /messages/{msgId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() &&
                       request.resource.data.authorUid == request.auth.uid &&
                       request.resource.data.text is string &&
                       request.resource.data.text.size() > 0 &&
                       request.resource.data.createdAt == request.time;
      allow update: if isAuthenticated() &&
                       resource.data.authorUid == request.auth.uid &&
                       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['text', 'editedAt', 'schemaVersion']) &&
                       request.resource.data.authorUid == resource.data.authorUid &&
                       request.resource.data.createdAt == resource.data.createdAt &&
                       request.resource.data.editedAt == request.time;
      allow delete: if isAuthenticated() &&
                       resource.data.authorUid == request.auth.uid;
    }
  }
}
```

---

## 🚀 Setup & Execution Guide

### Prerequisites
- Flutter SDK (3.47.5+ or compatible)
- Android SDK (API 35/36 installed, with Java 17)
- Firebase CLI (`npm install -g firebase-tools`)
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)

### Quick Start
1. **Clone the repository:**
   ```bash
   git clone <REPO_URL>
   cd Homework2_partone
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify Firebase configuration:**
   Configuration options are already bundled in `lib/firebase_options.dart` and `android/app/google-services.json` targeting Firebase project `fb-auth-lab-50718`.

4. **Run static analysis and tests:**
   ```bash
   flutter analyze
   flutter test
   ```

5. **Deploy Security Rules (Optional / Re-deploy):**
   ```bash
   firebase deploy --only firestore:rules
   ```

6. **Build and Run the Release APK:**
   ```bash
   flutter build apk --release
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 📱 App Architecture & Code Structure

```
lib/
├── firebase_options.dart      # FlutterFire generated configuration options
├── main.dart                  # App bootstrap, MaterialApp & theme initialization
├── models/
│   ├── message.dart           # Typed Message model with schema versioning
│   └── user_record.dart       # Authoritative 5-field Firestore user record model
├── screens/
│   ├── auth_gate.dart         # StreamBuilder listening to authStateChanges()
│   ├── board_screen.dart      # Real-time live board, composer, owner edit/delete & evidence suite
│   ├── login_screen.dart      # Validated sign-in with double-submit guard & error mapper
│   ├── profile_gate.dart      # Ensures 5-field profile existence; handles profile-retry flow
│   ├── register_screen.dart   # Registration form (First, Last, Role, Email, Password)
│   └── splash_screen.dart     # Styled branding splash screen with connection error retry
├── services/
│   ├── auth_service.dart      # Encapsulates all Firebase Authentication calls
│   ├── board_service.dart     # Encapsulates Firestore message CRUD, batching, migration
│   └── user_service.dart      # Encapsulates Firestore user record creation & verification
└── theme/
    └── app_theme.dart         # Material 3 styling (Late Fall / Burnt Orange palette)
```

---

## 🧪 Comprehensive Verification Checklist

| Test Phase | Action & Checkpoint | Expected Result | Status |
| :--- | :--- | :--- | :--- |
| **Launch** | Cold launch release APK | Styled splash screen appears, connects to Firebase, transitions to AuthGate. | ✅ PASS |
| **Auth Validation** | Submit empty/invalid login & registration | Clear error feedback ("Required", "Valid email required", "Min 6 chars"). | ✅ PASS |
| **Registration** | Register Ada Lovelace with role "Student" | Auth user created; Firestore document `users/{uid}` created with all 5 fields. | ✅ PASS |
| **Profile Gate** | Simulate missing user record for signed-in user | ProfileGate catches missing document and offers "Complete Profile" retry. | ✅ PASS |
| **Live Stream Read** | Open board on client | Board renders from `snapshots()` stream; shows intentional empty state when 0 posts. | ✅ PASS |
| **Create Message** | Post message from composer | Message appears live without refresh; server timestamp orders chronologically. | ✅ PASS |
| **Update Message** | Author edits their own message | Text changes; `editedAt` timestamp appears; original `createdAt` remains unchanged. | ✅ PASS |
| **Delete Message** | Author deletes own message | Selected message deleted; other messages remain unaffected; stream updates live. | ✅ PASS |
| **Rules Enforcement** | Cross-UID update attempt | Firestore denies write with `permission-denied` (verified via Evidence Tools). | ✅ PASS |
| **Main Spice** | Install & run exact release APK | Full smoke test executed on release APK with internet permissions verified. | ✅ PASS |
| **Spice #4** | Idempotent Double-Tap Drill | Rapid concurrent posts with idempotency key result in exactly 1 Firestore document. | ✅ PASS |
| **Spice #5** | Schema Shape-shifter | Seeded legacy v1 documents migrated losslessly to schema version 2 via batch update. | ✅ PASS |
| **Spice #6** | Batch Librarian | Atomic `WriteBatch` deletion clears all of author's messages simultaneously. | ✅ PASS |

---

## 📄 Deliverables Summary
1. **GitHub Repository:** Complete source code with architectural separation and development commits.
2. **Release APK:** Located at `release_apk/app-release.apk` (and `build/app/outputs/flutter-apk/app-release.apk`).
3. **Evidence Document:** Attached Word (`.docx`) and PDF (`.pdf`) containing all reflection prompts, AI comparison, case file answers, and captioned screenshots.
