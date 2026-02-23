# Segmentation Fault Fix for macOS 15 + Xcode 16

This document explains the segmentation fault issue and the automated solution implemented in this project.

## 🐛 The Problem

On **macOS 15 (Sequoia) with Xcode 16**, Expo projects encounter segmentation faults during the build process due to `bash -l -c` commands in build scripts. This happens because:

1. **EXConstants.podspec** uses `bash -l -c` in its script phase
2. **Xcode project file** contains `bash -l -c` in the "[Expo] Configure project" build phase
3. The `-l` flag invokes a login shell which causes crashes in non-interactive build environments

## ✅ The Solution

We've implemented a **multi-layered automated fix** that handles this issue:

### 1. **Automated Script (`scripts/fix-segfault.js`)**
- Automatically replaces `bash -l -c` with `/bin/bash -c` in both problematic files
- Runs before iOS builds and after prebuild operations
- Provides detailed feedback about what was fixed

### 2. **Enhanced Package.json Scripts**
```json
{
  "scripts": {
    "ios": "node ./scripts/fix-segfault.js && expo run:ios",
    "ios:fix": "node ./scripts/fix-segfault.js",
    "prebuild": "expo prebuild && node ./scripts/fix-segfault.js"
  }
}
```

### 3. **Podfile Automation**
- Fixes EXConstants.podspec during `pod install`
- Provides guidance for additional fixes needed

## 🚀 Usage

### **Recommended: Use the automated npm scripts**

```bash
# Run iOS with automatic fix
npm run ios

# Apply fix manually (if needed)
npm run ios:fix

# Prebuild with automatic fix
npm run prebuild
```

### **Alternative: Manual commands**
```bash
# If you need to run expo commands directly
npm run ios:fix && npx expo run:ios
```

## 🔧 How It Works

### **Files Fixed:**
1. **`node_modules/expo-constants/ios/EXConstants.podspec`**
   - Changes: `bash -l -c` → `/bin/bash -c`
   - When: During pod install (Podfile) + before iOS builds (script)

2. **`ios/FoundationApp.xcodeproj/project.pbxproj`**
   - Changes: `bash -l -c` → `/bin/bash -c` in "[Expo] Configure project" phase
   - When: Before iOS builds (script)

### **Automation Layers:**
1. **Podfile `post_install`** - Fixes EXConstants.podspec during `pod install`
2. **npm script** - Fixes both files before `expo run:ios`
3. **Manual script** - Available for on-demand fixes

## 🔄 When Fixes Are Applied

| Command | EXConstants Fix | Project File Fix | Notes |
|---------|----------------|------------------|-------|
| `npm run ios` | ✅ | ✅ | **Recommended** - Full automation |
| `npm run ios:fix` | ✅ | ✅ | Manual fix only |
| `npm run prebuild` | ✅ | ✅ | After prebuild automation |
| `pod install` | ✅ | ❌ | Podfile handles EXConstants only |
| `npx expo run:ios` | ❌ | ❌ | **Not recommended** - No fixes |

## 🚨 Important Notes

### **Always Use `npm run ios` Instead of `npx expo run:ios`**
- ✅ **Correct:** `npm run ios` (applies fixes automatically)
- ❌ **Avoid:** `npx expo run:ios` (no fixes applied)

### **Why the Problem Persists**
The segmentation fault returns after every `npx expo run:ios` because:
1. `expo run:ios` runs `expo prebuild` which regenerates iOS project files
2. `expo prebuild` can restore the problematic `bash -l -c` commands
3. Our automation only runs when using the npm scripts

### **If You Still Get Segmentation Faults**
1. **First, try:** `npm run ios:fix` then retry your build
2. **Check:** Make sure you're using `npm run ios` instead of `npx expo run:ios`
3. **Verify:** Run `npm run ios:fix` and check the output for successful fixes

## 🔍 Troubleshooting

### **Script Not Found Error**
```bash
# Make sure the script is executable
chmod +x scripts/fix-segfault.js
```

### **Still Getting Segmentation Faults**
```bash
# Apply fixes manually and check output
npm run ios:fix

# Then try building again
npm run ios
```

### **Files Not Found**
If the script reports files not found:
- Run `npm install` to ensure all dependencies are installed
- Run `npx expo prebuild` to generate iOS project files
- Then run `npm run ios:fix`

## 📋 Summary

This automated solution ensures that:
- ✅ Segmentation faults are prevented automatically
- ✅ Fixes are applied before every iOS build
- ✅ No manual intervention required for normal development
- ✅ Multiple layers of protection against the issue

**Just remember to use `npm run ios` instead of `npx expo run:ios` and you'll never see the segmentation fault again!** 🎉
