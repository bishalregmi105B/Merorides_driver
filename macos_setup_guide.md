# Complete macOS Setup Guide - MeroRides Driver & Rider Apps

This guide walks you through everything needed to run the MeroRides Driver and Rider iOS apps on macOS, from scratch.

---

## Prerequisites

### System Requirements
- **macOS**: Version 12.0 (Monterey) or later
- **Free Disk Space**: At least 50 GB (for Xcode, Flutter, and builds)
- **Apple ID**: Free Apple ID (for simulator) or paid Apple Developer Account ($99/year for physical devices)
- **RAM**: 8 GB minimum, 16 GB recommended
- **Processor**: Intel or Apple Silicon (M1/M2/M3)

---

## Step 1: Install Xcode

### 1.1 Download and Install Xcode

**Option A: From App Store (Recommended)**
```bash
# Open App Store and search for "Xcode", or use this command:
open "macappstore://apps.apple.com/app/xcode/id497799835"
```

- Click **Get** → **Install**
- Wait for download (12-15 GB, takes 30-60 minutes depending on internet speed)
- Enter your Apple ID password when prompted

**Option B: From Apple Developer Website**
1. Visit https://developer.apple.com/download/
2. Sign in with your Apple ID
3. Download the latest Xcode .xip file
4. Extract and move to Applications folder

### 1.2 Complete Xcode Setup

After installation, run these commands in Terminal:

```bash
# Set Xcode command-line tools path
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Accept Xcode license
sudo xcodebuild -license accept

# Install additional required components
sudo xcodebuild -runFirstLaunch
```

### 1.3 Open Xcode
```bash
open /Applications/Xcode.app
```

- Accept any additional license agreements
- Wait for additional components to install
- You can close Xcode after setup completes

### 1.4 Verify Installation
```bash
xcodebuild -version
```
**Expected output**: `Xcode 15.x` or later

---

## Step 2: Install Homebrew (Package Manager)

Homebrew makes it easy to install development tools.

### 2.1 Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the prompts and enter your password when asked.

### 2.2 Add Homebrew to PATH
```bash
# For Intel Macs:
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"

# For Apple Silicon (M1/M2/M3) Macs:
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 2.3 Verify Installation
```bash
brew --version
```

---

## Step 3: Install Flutter

### 3.1 Download Flutter SDK
```bash
cd ~/Downloads
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.35.4-stable.zip
```

### 3.2 Extract and Move Flutter
```bash
unzip flutter_macos_3.35.4-stable.zip
sudo mv flutter /usr/local/
```

### 3.3 Add Flutter to PATH
```bash
echo 'export PATH="$PATH:/usr/local/flutter/bin"' >> ~/.zprofile
source ~/.zprofile
```

### 3.4 Verify Flutter Installation
```bash
flutter --version
```

### 3.5 Run Flutter Doctor
```bash
flutter doctor
```

This command checks your environment. You should see:
- ✓ Flutter
- ✓ Xcode
- Some items may still show issues - we'll fix them next

---

## Step 4: Install CocoaPods

CocoaPods manages iOS dependencies.

### 4.1 Install CocoaPods
```bash
sudo gem install cocoapods
```

If you get permission errors, try:
```bash
sudo gem install -n /usr/local/bin cocoapods
```

### 4.2 Verify Installation
```bash
pod --version
```
**Expected**: Version 1.12 or later

---

## Step 5: Accept iOS Licenses

```bash
sudo xcodebuild -license accept
```

---

## Step 6: Set Up iOS Simulator

### 6.1 Open Simulator
```bash
open -a Simulator
```

### 6.2 Choose a Device
In Simulator menu:
- **File** → **Open Simulator** → Choose device (e.g., "iPhone 15 Pro")

### 6.3 Verify Simulator Works
```bash
flutter devices
```
You should see your simulator listed.

---

## Step 7: Prepare Your Project Files

### 7.1 Transfer Project to Mac

**Option A: Using Git**
```bash
cd ~/Documents
git clone <your-repository-url>
cd "Ride (2)/Files/Flutter/Driver"
```

**Option B: Copy from USB/Cloud**
- Copy the project folder to your Mac
- Example location: `~/Documents/Ride (2)/Files/Flutter/Driver`

### 7.2 Navigate to Project
```bash
cd ~/Documents/Ride\ \(2\)/Files/Flutter/Driver
```

---

## Step 8: Build Driver App

### 8.1 Clean Previous Builds
```bash
flutter clean
```

### 8.2 Get Flutter Dependencies
```bash
flutter pub get
```

Wait for all packages to download (2-5 minutes).

### 8.3 Install iOS Pods
```bash
cd ios
pod install
cd ..
```

**Note**: First run takes 5-10 minutes, subsequent runs are faster.

### 8.4 Run on Simulator
```bash
flutter run
```

**Or specify the device:**
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

### 8.5 Build for Release (Optional)
```bash
# Build without code signing (for testing)
flutter build ios --no-codesign

# Build with code signing (requires Apple Developer Account)
flutter build ios --release
```

---

## Step 9: Build Rider App

### 9.1 Navigate to Rider Project
```bash
cd ~/Documents/Ride\ \(2\)/Files/Flutter/Driver/Rider
```

### 9.2 Clean and Get Dependencies
```bash
flutter clean
flutter pub get
```

### 9.3 Install iOS Pods
```bash
cd ios
pod install
cd ..
```

### 9.4 Run on Simulator
```bash
flutter run
```

---

## Step 10: Run on Physical iPhone (Optional)

### 10.1 Connect Your iPhone
- Connect iPhone to Mac via USB cable
- On iPhone: **Settings** → **Privacy & Security** → **Developer Mode** → Enable
- Unlock your iPhone and tap **Trust** when prompted

### 10.2 Free Provisioning (No Developer Account)

Open Xcode:
```bash
cd ~/Documents/Ride\ \(2\)/Files/Flutter/Driver/ios
open Runner.xcworkspace
```

In Xcode:
1. Select **Runner** in the project navigator
2. Go to **Signing & Capabilities** tab
3. Check **Automatically manage signing**
4. Select your **Team** (your Apple ID)
5. Change **Bundle Identifier** to something unique:
   - For Driver: `com.yourname.meroridesdriver`
   - For Rider: `com.yourname.meroridesuser`

### 10.3 Update Bundle ID in Flutter

**Driver App:**
Edit [ios/Runner.xcodeproj/project.pbxproj](file:///home/bishal-regmi/Downloads/Ride%20%282%29/Files/Flutter/Driver/ios/Runner.xcodeproj/project.pbxproj) or use Xcode as shown above.

**Rider App:**
Same process in `Rider/ios/Runner.xcworkspace`

### 10.4 Run on Physical Device
```bash
# List connected devices
flutter devices

# Run on your iPhone
flutter run -d <your-iphone-device-id>
```

---

## Step 11: Build IPA for Distribution

### 11.1 Create Archive
```bash
flutter build ios --release
```

### 11.2 Open in Xcode
```bash
cd ios
open Runner.xcworkspace
```

### 11.3 Archive the App
In Xcode:
1. Select **Any iOS Device (arm64)** as the build target
2. Menu: **Product** → **Archive**
3. Wait for archive to complete (5-10 minutes)
4. **Organizer** window opens automatically

### 11.4 Distribute App

**For App Store:**
1. Click **Distribute App**
2. Choose **App Store Connect**
3. Follow wizard to upload

**For Ad Hoc/Enterprise:**
1. Click **Distribute App**
2. Choose **Ad Hoc** or **Enterprise**
3. Select **Export** to save .ipa file

---

## Troubleshooting

### Issue: "pod: command not found"

**Fix:**
```bash
sudo gem install cocoapods
# Or
brew install cocoapods
```

### Issue: "Unable to boot simulator"

**Fix:**
```bash
# Restart simulator service
killall Simulator
open -a Simulator
```

### Issue: "Xcode license agreement"

**Fix:**
```bash
sudo xcodebuild -license accept
```

### Issue: "No module named 'Flutter'"

**Fix:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### Issue: CocoaPods Slow on Apple Silicon

**Fix:**
```bash
# Install Ruby via Homebrew
brew install ruby

# Use Homebrew Ruby
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zprofile
source ~/.zprofile

# Reinstall CocoaPods
gem install cocoapods
```

### Issue: Build fails with "GoogleMaps" error

**Fix:**
Check that Google Maps API key is set in:
- `ios/Runner/AppDelegate.swift`
- `android/app/src/main/AndroidManifest.xml`

### Issue: "Provisioning Profile doesn't include signing certificate"

**Fix:**
1. Open Xcode
2. Go to **Xcode** → **Preferences** → **Accounts**
3. Click **Download Manual Profiles**
4. Try building again

---

## Quick Reference Commands

### Driver App
```bash
# Navigate to project
cd ~/Documents/Ride\ \(2\)/Files/Flutter/Driver

# Build and run
flutter clean && flutter pub get
cd ios && pod install && cd ..
flutter run

# Build release
flutter build ios --release
```

### Rider App
```bash
# Navigate to project
cd ~/Documents/Ride\ \(2\)/Files/Flutter/Driver/Rider

# Build and run
flutter clean && flutter pub get
cd ios && pod install && cd ..
flutter run

# Build release
flutter build ios --release
```

---

## Tips & Best Practices

### 1. Keep Xcode Updated
```bash
# Check for updates
softwareupdate --list

# Install updates
softwareupdate --install --all
```

### 2. Clean Periodically
When switching branches or after major changes:
```bash
flutter clean
cd ios
pod deintegrate
pod install
cd ..
flutter pub get
```

### 3. Use Simulator for Development
- Faster build times
- No need for certificates
- Easy to test multiple device sizes
- Use physical device for final testing

### 4. Monitor Build Times
First build takes 10-20 minutes. Subsequent builds are 1-2 minutes.

### 5. Hot Reload
While app is running:
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

---

## Next Steps After Setup

### For Development
1. ✅ Both apps running on simulator
2. Test core features
3. Make code changes and use hot reload
4. Run on physical device for final testing

### For Production
1. Set up proper code signing with Apple Developer Account
2. Configure push notifications certificates
3. Set up App Store Connect
4. Create app listings
5. Submit for App Store review

### For Testing
1. Use TestFlight for beta testing
2. Distribute Ad Hoc builds to testers
3. Use Firebase Test Lab for automated testing

---

## Useful Resources

- **Flutter Documentation**: https://docs.flutter.dev
- **Xcode Documentation**: https://developer.apple.com/documentation/xcode
- **CocoaPods**: https://cocoapods.org
- **App Store Connect**: https://appstoreconnect.apple.com
- **Flutter iOS Setup**: https://docs.flutter.dev/get-started/install/macos/mobile-ios

---

## Summary Checklist

- [ ] macOS 12.0+ installed
- [ ] Xcode installed and configured
- [ ] Homebrew installed
- [ ] Flutter SDK installed
- [ ] CocoaPods installed
- [ ] iOS licenses accepted
- [ ] Simulator running
- [ ] Driver app builds successfully
- [ ] Rider app builds successfully
- [ ] Apps run on simulator
- [ ] (Optional) Apps run on physical device
- [ ] (Optional) IPA files created

**Once all items are checked, you're ready for iOS development! 🎉**
