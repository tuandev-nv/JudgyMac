# Release & Auto-Update Setup

## Overview

JudgyMac uses [Sparkle 2](https://sparkle-project.org/) for auto-updates.

- **Appcast URL**: `https://judgymac.xyz/appcast.xml`
- **Download URL**: `https://judgymac.xyz/v1/apps/com.judgymac.app/download`

## 1. Generate Signing Keys (One-Time)

```bash
# From Sparkle package in DerivedData or checkout
./bin/generate_keys

# Output: saves private key to Keychain, prints public key
# Copy the public key to Info.plist → SUPublicEDKey
```

Export private key for CI:
```bash
./bin/generate_keys -x sparkle_private_key
# Keep this file SAFE — never commit to git
```

## 2. Build & Sign a Release

```bash
# 1. Archive
xcodebuild archive -scheme JudgyMac -archivePath build/JudgyMac.xcarchive

# 2. Export .app
xcodebuild -exportArchive -archivePath build/JudgyMac.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath build/

# 3. Re-sign with ad-hoc (Sparkle framework needs matching signature)
codesign --force --deep --sign - build/JudgyMac.app

# 4. Create DMG
hdiutil create -volname "JudgyMac" -srcfolder build/JudgyMac.app \
  -ov -format UDZO build/JudgyMac-v1.0.0.dmg

# 4. Sign DMG with Sparkle EdDSA
./bin/sign_update build/JudgyMac-v1.0.0.dmg
# Output: sparkle:edSignature="..." length="..."
# Copy these values into appcast.xml
```

## 3. Appcast.xml Format

Host at `https://judgymac.xyz/appcast.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>JudgyMac Updates</title>
    <language>en</language>

    <item>
      <title>Version 1.0.1</title>
      <sparkle:version>2</sparkle:version>
      <sparkle:shortVersionString>1.0.1</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <description><![CDATA[
        <ul>
          <li>Bug fixes and improvements</li>
        </ul>
      ]]></description>
      <pubDate>Wed, 02 Apr 2026 12:00:00 +0700</pubDate>
      <enclosure
        url="https://judgymac.xyz/downloads/JudgyMac-v1.0.1.dmg"
        type="application/octet-stream"
        sparkle:edSignature="SIGNATURE_HERE"
        length="FILE_SIZE_BYTES"
      />
    </item>

  </channel>
</rss>
```

### Fields

| Field | Description |
|-------|-------------|
| `sparkle:version` | Build number (`CFBundleVersion`), must increment |
| `sparkle:shortVersionString` | Display version (`CFBundleShortVersionString`) |
| `sparkle:edSignature` | EdDSA signature from `sign_update` tool |
| `length` | File size in bytes |
| `url` | Direct download URL for the DMG |

## 4. Server Setup (Nginx)

### Appcast + Download Endpoint

```nginx
server {
    listen 443 ssl;
    server_name judgymac.xyz;

    root /var/www/judgymac-releases;

    # Appcast XML
    location /appcast.xml {
        add_header Content-Type "application/xml";
    }

    # Download endpoint — always serves latest version
    # GET /v1/apps/com.judgymac.app/download → redirect to latest DMG
    location /v1/apps/com.judgymac.app/download {
        return 302 /downloads/JudgyMac-latest.dmg;
    }

    # Static DMG files
    location /downloads/ {
        add_header Content-Disposition "attachment";
    }
}
```

### Directory Structure

```
/var/www/judgymac-releases/
├── appcast.xml
└── downloads/
    ├── JudgyMac-latest.dmg      → symlink to latest version
    ├── JudgyMac-v1.0.0.dmg
    └── JudgyMac-v1.0.1.dmg
```

### Updating Releases

```bash
# Upload new DMG
scp JudgyMac-v1.0.1.dmg server:/var/www/judgymac-releases/downloads/

# Update symlink
ssh server 'cd /var/www/judgymac-releases/downloads && \
  ln -sf JudgyMac-v1.0.1.dmg JudgyMac-latest.dmg'

# Update appcast.xml with new item
scp appcast.xml server:/var/www/judgymac-releases/
```

## 5. Release Checklist

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`
2. Archive & export `.app`
3. Create DMG
4. Sign DMG with `sign_update`
5. Upload DMG to server
6. Update `appcast.xml` with new `<item>`
7. Update `JudgyMac-latest.dmg` symlink
8. Verify: `curl -I https://judgymac.xyz/v1/apps/com.judgymac.app/download`

## 6. Info.plist Keys

| Key | Value |
|-----|-------|
| `SUFeedURL` | `https://judgymac.xyz/appcast.xml` |
| `SUPublicEDKey` | Base64 EdDSA public key |
| `SUEnableAutomaticChecks` | `true` |

## 7. Signing Notes

### Sparkle EdDSA vs Apple Developer ID — Hai thứ khác nhau hoàn toàn

| | Sparkle EdDSA (`sign_update`) | Apple Developer ID / Notarization |
|---|---|---|
| **Mục đích** | Verify DMG không bị tamper khi auto-update | macOS Gatekeeper cho phép mở app |
| **Cần account** | Không, chỉ cần key local | Apple Developer ($99/năm) |
| **Bắt buộc?** | Bắt buộc cho Sparkle update | Không bắt buộc, nhưng nếu không có thì user phải right-click → Open |
| **Key ở đâu** | Private key trong Keychain, public key trong Info.plist | Certificate từ Apple Developer Portal |

**Kết luận**: Sparkle auto-update hoạt động hoàn toàn **không cần** Apple Developer account. Chỉ cần EdDSA key đã generate.

### Sparkle Tools Location

```bash
# generate_keys (đã chạy, key lưu trong Keychain)
~/Library/Developer/Xcode/DerivedData/JudgyMac-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys

# sign_update (dùng khi release DMG)
~/Library/Developer/Xcode/DerivedData/JudgyMac-*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update JudgyMac-v1.0.0.dmg

# Export private key (backup, KHÔNG commit vào git)
~/Library/Developer/Xcode/DerivedData/JudgyMac-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys -x sparkle_private_key
```
