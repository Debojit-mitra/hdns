# HDNS

A simple Private DNS switcher for Android. Pick a DNS provider, tap once, and it applies system-wide. A Quick Settings tile lets you turn it on or off, or switch providers, straight from the notification panel.

## Features

- One-tap switching between built-in DNS providers (Cloudflare, Google, Quad9, AdGuard, Mullvad, CleanBrowsing)
- Add, edit and delete your own custom DNS
- Quick Settings tile: tap to toggle, long-press to pick a provider
- Checks that the new DNS actually resolves, and offers to revert if it doesn't
- Dynamic color, light and dark themes
- Notifies you in-app when a new release is available

## Screenshots

<p align="center">
  <img src="https://i.ibb.co/8nh7w1YP/Screenshot-1.webp" width="30%" alt="Home" />
  <img src="https://i.ibb.co/rRnGKPm4/Screenshot-2.webp" width="30%" alt="Quick Settings tile" />
  <img src="https://i.ibb.co/Fbj1DrWw/Screenshot-3.webp" width="30%" alt="Settings" />

</p>

## How it works

HDNS uses Android's built-in **Private DNS** (DNS-over-TLS) setting. Because of that, a custom DNS must be a **hostname** like `dns.example.com`, not an IP address.

## Setup

Android only lets an app change Private DNS after a one-time permission. With USB or wireless debugging on, run this once from a computer:

```
adb shell pm grant com.hana.utils.hdns android.permission.WRITE_SECURE_SETTINGS
```

The app's setup screen shows this command with a copy button, and moves on by itself once it works. You don't need to repeat it unless you uninstall the app.

## Quick Settings tile

- **Tap:** turn DNS on or off
- **Long-press:** choose a different DNS provider

On Android 13+, add the tile from **Settings → Add tile** inside the app. On older versions, add it from the Quick Settings edit menu.

## Requirements

- Android 9 (API 28) or newer

## Build from source

```
flutter pub get
flutter run
```

## Updates

HDNS checks the latest GitHub release when it opens. If a newer version exists, it shows the release notes and a button that opens the release page.

## License

Released under the [MIT License](LICENSE).

---

Made with ❤️ by Debojit
