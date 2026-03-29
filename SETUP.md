# QRostlina - Firebase & Security Setup

This document describes how to set up the backend services for the QRostlina application.

## 1. Firebase Project Setup
1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Create a new project named `qrostlina`.
3.  **Authentication**:
    *   Enable **Google** as a sign-in provider.
    *   **Crucial**: Set the **Project support email** in the Google provider settings.
4.  **Firestore Database**:
    *   Create a database in **Production Mode**.
    *   Choose a location (e.g., `eur3` for Europe).

## 2. Android Integration
1.  Add an Android App to the Firebase project with package name: `com.example.qrostlina`.
2.  **SHA-1 Fingerprint**:
    *   Generate your local debug SHA-1: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
    *   Add the SHA-1 to the app settings in the Firebase Console.
3.  **Config File**:
    *   Download `google-services.json` and place it in `android/app/`.
    *   *Note: This file is ignored by Git to protect secrets.*

## 3. Firestore Security Rules (Whitelist Mode)
Copy and paste these rules into the **Rules** tab of your Firestore Database in the Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Master Admin check (Hardcoded failsafe)
    function isMasterAdmin() {
      return request.auth != null && 
             request.auth.token.email == 'karel.zak.007@gmail.com';
    }

    // Helper function to check if the user's email is on the whitelist
    function isWhitelisted() {
      return request.auth != null && (
        isMasterAdmin() ||
        exists(/databases/$(database)/documents/authorized_users/$(request.auth.token.email))
      );
    }

    // Protect species data
    match /species/{doc} { 
      allow read, write: if isWhitelisted(); 
    }
    
    // Protect location data (beds and crates)
    match /beds/{doc} { allow read, write: if isWhitelisted(); }
    match /crates/{doc} { allow read, write: if isWhitelisted(); }

    // Allow whitelisted users to manage the whitelist itself
    match /authorized_users/{email} {
      allow read, write: if isWhitelisted();
    }
  }
}
```

## 4. Bootstrapping (The First User)
Because the rules block everyone not on the whitelist, you must manually add the first administrator:
1.  In the Firebase Console, go to **Firestore Database** -> **Data**.
2.  Click **Start collection** and name it `authorized_users`.
3.  For **Document ID**, type your full Gmail address (e.g., `your.email@gmail.com`).
4.  Add a field `role: "admin"` (the value doesn't matter, just the existence of the document).

## 5. App Configuration
1.  Open the app and go to **Settings** -> **Auth**.
2.  Sign in with your Google account.
3.  Go to **General** and toggle **Cloud Mode** to ON.
4.  Go to **Data** and click **Push Local Data to Cloud** if you have existing local data.
5.  Go to **Access** to manage other authorized users.

## 6. Linux (Fedora/RHEL/Modern) USB Troubleshooting
If `flutter devices` shows your device as "unsupported" or `adb devices` shows "no permissions", follow these steps:

1.  **Identify your Device ID:**
    Run `lsusb`. Look for your device (e.g., `ID 18d1:4ee7`).
2.  **Create/Edit the udev rule:**
    ```bash
    sudo vi /etc/udev/rules.d/51-android.rules
    ```
    Add the following line (replacing IDs if necessary):
    ```text
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee7", MODE="0666", TAG+="uaccess"
    ```
    *(Note: Using `TAG+="uaccess"` grants permissions to the currently logged-in user on modern systems like Fedora.)*
3.  **Reload and Trigger:**
    ```bash
    sudo udevadm control --reload-rules && sudo udevadm trigger
    ```
4.  **Reconnect Device:**
    **Unplug your phone and plug it back in** for the new rules to apply to the device.
5.  **Restart ADB:**
    ```bash
    adb kill-server
    adb devices
    ```
    Once done, check your phone for the "Allow USB Debugging?" prompt.

## 7. Android Distribution Scenarios
If you want to share the app with other gardeners without using the Google Play Store:

### Scenario A: Direct APK Sharing (Easiest)
1.  **Build**: Run `./scripts/deploy_android.sh --build`.
2.  **File**: Send the generated `app-release-arm64-v8a.apk` (found in `build/app/outputs/flutter-apk/`) to the user via Signal, WhatsApp, or email.
3.  **Install**: The user opens the file on their phone and selects "Allow installation from unknown sources".

### Scenario B: GitHub Releases (Semi-Public)
1.  Tag a version: `git tag v1.0.0 && git push origin v1.0.0`.
2.  Create a **Release** on GitHub and upload the `.apk` files there.
3.  Users can download the latest version from the repository's "Releases" page.

### Scenario C: Firebase App Distribution (Private/Controlled)
1.  In the **Firebase Console**, navigate to the left sidebar: **Release & Monitor** -> **App Distribution** (sometimes found under **DevOps & Engagement**).
2.  Upload the `app-release.apk`.
3.  Add the gardeners' emails. They will receive an invitation to install the "App Tester" and get updates automatically.
