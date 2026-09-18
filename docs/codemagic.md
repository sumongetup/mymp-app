# Codemagic দিয়ে অ্যাপ বিল্ড

রিপোজিটরির `codemagic.yaml`-এ তিনটা ওয়ার্কফ্লো আছে:

| ওয়ার্কফ্লো | কখন চলে | কী করে |
|---|---|---|
| `android-check` | Start new build থেকে | analyze আর test; কিছু সাইন হয় না |
| `android-release` | Start new build থেকে | analyze, test, আপলোড কী দিয়ে সাইন করা AAB আর APK |
| `ios-release` | Start new build থেকে | analyze, test, App Store-এর IPA, সোজা TestFlight-এ আপলোড |

## একবারের কাজ

### ১. আপলোড কী তৈরি (নিজের পাসওয়ার্ড দিয়ে)

```bash
"/c/Program Files/Android/Android Studio/jbr/bin/keytool.exe" -genkeypair -v -keystore "C:/Users/User/mymp-upload.jks" -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

পাসওয়ার্ড আর নাম-পরিচয় জিজ্ঞেস করবে। **এই .jks ফাইল আর পাসওয়ার্ড হারালে Play-তে এই অ্যাপ আর আপডেট করা যাবে না।** দুটো জায়গায় ব্যাকআপ রাখুন। ফাইলটা কখনো GitHub-এ দেবেন না।

### ২. Codemagic-এ অ্যাপ যোগ

রিপোজিটরিটা public, তাই কোনো কী বা অনুমতি লাগে না।

1. **Add application** > Git provider **Other** (GitHub নয়)।
2. Repository URL: `https://github.com/sumongetup/mymp-app.git`। SSH key আর password ফাঁকা রাখুন।
3. Project type **Flutter App** (না থাকলে **Other**), তারপর **Add application**। Codemagic নিজেই `codemagic.yaml` পড়বে।

এভাবে যোগ করা অ্যাপে GitHub-এর push বা ট্যাগ Codemagic-এ পৌঁছায় না, তাই বিল্ড নিজে চালাতে হয় (নিচে দেখুন)।

### ৩. আপলোড কী Codemagic-এ দিন

**Settings (বা Team settings) > Code signing identities > Android keystores > Add keystore**

- Keystore file: `mymp-upload.jks`
- Keystore password, Key alias (`upload`), Key password: আপনার দেওয়া
- **Reference name: `mymp_upload`** (হুবহু এটাই, `codemagic.yaml` এই নাম খোঁজে)

### ৪. iOS-এর জন্য (একবারই)

অ্যাপের bundle ID: **`bd.mymp.app`** (Android-এর মতোই)। Codemagic-এ Apple-এর API কী আগে থেকেই আছে (`ftp_app_store_key`, Find Travel Partner-এর জন্য দেওয়া), একই Apple অ্যাকাউন্ট দিয়ে এই অ্যাপও চলবে।

1. **developer.apple.com > Certificates, IDs & Profiles > Identifiers > +** > App IDs > App। Description `Amar MP`, Bundle ID **Explicit** `bd.mymp.app`। কোনো Capability লাগবে না। Register।
2. **Profiles > +** > **App Store Connect** (Distribution)। App ID `bd.mymp.app`, সার্টিফিকেট আগের Apple Distribution-টা। নাম `mymp App Store`। Generate।
3. **appstoreconnect.apple.com > Apps > + > New App**: Platform iOS, Name `আমার এমপি` (নেওয়া থাকলে `আমার এমপি - MyMP`), Primary language Bengali, Bundle ID `bd.mymp.app`, SKU `mymp`।
4. Codemagic > **Settings > Code signing identities > iOS provisioning profiles > Fetch profiles** > `mymp App Store` বেছে যোগ করুন। **iOS certificates** ট্যাবে Apple Distribution সার্টিফিকেট আছে কি না দেখুন।

## প্রতিটা রিলিজ

1. `pubspec.yaml`-এ `version: 1.2.4+7`-এর `+`-এর পরের সংখ্যা এক বাড়ান (Play প্রতিবার বড় সংখ্যা চায়)।
2. কমিট করে `main`-এ push করুন।
3. Codemagic-এ অ্যাপ খুলে **Start new build** > branch `main` > workflow **Android release (signed AAB)** > **Start new build**।
4. শেষে **Artifacts** থেকে `app-release.aab` নামিয়ে Play Console-এ তুলুন। `app-release.apk` সরাসরি ফোনে ইনস্টলের জন্য।
5. iOS: একইভাবে workflow **iOS release (TestFlight)** চালান। বিল্ড নিজেই App Store Connect-এ যায়, ১০-৩০ মিনিট পর TestFlight-এ দেখাবে। App Review-এ পাঠানো App Store Connect থেকে নিজে করবেন।

## কী না থাকলে

রিলিজ বিল্ড ইচ্ছা করেই থেমে যায় ("No upload key…"), debug কী দিয়ে সাইন করে না, কারণ Play debug-সাইন করা বান্ডেল নেয় না। শেষ ধাপে বিল্ড যাচাই করে যে বান্ডেলটা আপলোড কী দিয়েই সাইন করা।

## পরে চাইলে

Play-তে সরাসরি আপলোড: Google Play Console থেকে service account তৈরি করে Codemagic-এর **Team settings > Integrations > Google Play**-তে দিন, তারপর `codemagic.yaml`-এর নিচের `publishing` অংশের কমেন্ট তুলে দিন।
