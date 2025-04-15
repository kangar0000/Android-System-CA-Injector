# Android System CA Injector (Magisk Module)

A simple Magisk module that injects user-added CA certificates into the system trust store on Android 14 and above.

This project is based entirely on the work by Tim Perry, who documented how Android 14 changed system certificate handling:  
👉 https://httptoolkit.com/blog/android-14-install-system-ca-certificate/#how-to-install-system-ca-certificates-in-android-14

In the original blog, certificate injection is **temporary** — the changes are lost after every reboot.  
This module makes that process **persistent** by automatically re-injecting certificates on each boot, so you don't need to manually repeat commands.

---

## ✅ Requirements

- Android 14 and above
- Magisk installed
- Rooted Device
- adb.exe - https://developer.android.com/tools/releases/platform-tools

---

## 📦 Installation

1. Run following commands in your CLI:

```bash
adb push SystemCAInjector.zip /sdcard/download
adb shell
su
magisk --install-module /sdcard/download/SystemCAInjector.zip
reboot
```

2. After boot, you can find user-added CA certs in your system CA

---

## 🛠️ Troubleshooting

- Check logs via:
  ```
  cat /data/local/tmp/auto-ca.log
  ```

---

### ⚠️ Notes

- All certificates in the user store (`/data/misc/user/0/cacerts-added/`) will be injected — make sure they are trusted
- If multiple certs share the same hash (e.g. `.0`, `.1`), only the latest version is kept
- You can add multiple certificates at once

---