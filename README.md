# LocationTrackerApp (iOS) — Google auth + periodic location upload

This repo contains:

- `iOSAppTemplate/LocationTrackerApp/`: SwiftUI iOS app code that signs in with Google, tracks location (incl. background), and sends it to your web server **every X seconds** (throttled).
- `LocationTrackerApp/Tools/TestServer/server.py`: a tiny local server to receive the POSTs.

## What gets sent

The app sends `POST <serverURL>` with:

- Header: `Authorization: Bearer <google_id_token>`
- JSON body:

```json
{
  "latitude": 37.3317,
  "longitude": -122.0301,
  "horizontalAccuracy": 8.2,
  "altitude": 12.3,
  "speed": 0.0,
  "course": 0.0,
  "timestampISO8601": "2026-01-09T12:34:56Z",
  "deviceId": "A1B2C3..."
}
```

## iOS setup (Xcode)

### 1) Create an iOS app

In Xcode:

- File → New → Project → iOS → **App**
- Interface: **SwiftUI**
- Language: **Swift**
- Minimum iOS: **16.0+**

### 2) Add Google Sign-In dependency

In Xcode:

- File → Add Package Dependencies…
- Add package: `https://github.com/google/GoogleSignIn-iOS`
- Add products to your app target:
  - `GoogleSignIn`
  - `GoogleSignInSwift`

### 3) Copy the app source files

Copy everything from:

- `iOSAppTemplate/LocationTrackerApp/`

into your Xcode app target (same module).

### 4) Configure Google Sign-In (required)

You need an **iOS OAuth client** and a URL scheme.

Option A (recommended): **Firebase-style `GoogleService-Info.plist`**

- Create a Firebase project (or use Google Cloud Console + Firebase if you want easy iOS setup).
- Add an iOS app in Firebase.
- Download `GoogleService-Info.plist`
- Add it to your Xcode project (make sure it’s included in the app target).
- In Xcode target settings, add the URL scheme using `REVERSED_CLIENT_ID` from that plist.

Option B: **Manual Info.plist values**

- Open `iOSAppTemplate/LocationTrackerApp/Supporting/Info.plist`
- Copy these keys into your app’s Info.plist:
  - `GIDClientID` = your iOS client id (`...apps.googleusercontent.com`)
  - `CFBundleURLTypes` → URL scheme = your **reversed** client id

Google Console notes:

- Google Cloud Console → APIs & Services → Credentials
- Create OAuth client ID → **iOS**
- Bundle ID must match your Xcode app bundle id.

### 5) Location permissions + background mode

In your app target:

- Capabilities → Background Modes → enable **Location updates**
- Info.plist: add the location usage strings and `UIBackgroundModes = location`
  - You can copy from `iOSAppTemplate/LocationTrackerApp/Supporting/Info.plist`

## Running / testing

### Local test server

Run:

```bash
python3 LocationTrackerApp/Tools/TestServer/server.py
```

Then, in the iOS app UI set:

- Server URL: `http://<your-mac-ip>:8787/location`

Notes:

- `localhost` from an iPhone simulator refers to the simulator; from a physical device it refers to the device itself.
- For physical devices, use your Mac’s LAN IP and ensure firewall allows port `8787`.

### Background behavior caveat

iOS does **not** guarantee “every X seconds” network execution in the background via timers.
This app achieves best-effort background sending by:

- enabling background **location** updates,
- using **Significant Location Change** + **Visits** monitoring (so iOS can wake/relaunch the app on movement), and
- sending on each location update/visit, **throttled** to your configured interval.

If the device is stationary and iOS delivers fewer location updates, sends will happen less frequently.

Important: if the user **force-quits** the app (swipe it away in the app switcher), iOS will stop background location delivery until the user manually opens the app again.

### “Works when enabled even after closing” checklist

- In the app UI, enable **Tracking enabled**.
- Set **Mode**:
  - **Low power** for best battery / background relaunch on movement
  - **Standard** for more frequent updates (higher battery)
- iOS Settings → Privacy & Security → Location Services:
  - App permission: **Always**
  - Enable **Precise Location** (if you need accuracy)
- Xcode target:
  - Capabilities → Background Modes → **Location updates**
- Don’t force-quit the app (force-quit disables background relaunch).

## Security / server verification

Your server should verify the Google ID token:

- Validate JWT signature and claims (issuer, audience = your iOS client id, expiry), **or**
- Use Google’s tokeninfo endpoint (simpler but adds network dependency).

The server receives the token in:

- `Authorization: Bearer <idToken>`

