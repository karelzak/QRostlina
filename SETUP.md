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
    
    // Helper function to check if the user's email is on the whitelist
    function isWhitelisted() {
      return request.auth != null && 
             exists(/databases/$(database)/documents/authorized_users/$(request.auth.token.email));
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
