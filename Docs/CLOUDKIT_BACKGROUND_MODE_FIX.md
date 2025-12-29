# CloudKit Sync Fix - Background Modes

## Add Remote Notification Support

To enable CloudKit push notifications for better sync performance, you need to add background modes to your Info.plist.

### Option 1: Via Xcode UI (Easiest)

1. Select your **Reczipes2** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **Background Modes**
5. Check the box for **Remote notifications**

### Option 2: Manual Info.plist Edit

Add this to your `Info.plist` file:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

## What This Does

- Allows CloudKit to wake your app in the background when data changes
- Improves sync responsiveness (changes appear faster on other devices)
- Required for proper CloudKit push notification support

## After Adding

Rebuild your app and you should no longer see the warning:
```
BUG IN CLIENT OF CLOUDKIT: CloudKit push notifications require the 'remote-notification' background mode
```
