# Codemagic দিয়ে অ্যাপ বিল্ড

রিপোজিটরির `codemagic.yaml`-এ দুটো ওয়ার্কফ্লো আছে:

| ওয়ার্কফ্লো | কখন চলে | কী করে |
|---|---|---|
| `android-check` | Start new build থেকে | analyze আর test; কিছু সাইন হয় না |
| `android-release` | Start new build থেকে | analyze, test, আপলোড কী দিয়ে সাইন করা AAB আর APK |

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

## প্রতিটা রিলিজ

1. `pubspec.yaml`-এ `version: 1.2.4+7`-এর `+`-এর পরের সংখ্যা এক বাড়ান (Play প্রতিবার বড় সংখ্যা চায়)।
2. কমিট করে `main`-এ push করুন।
3. Codemagic-এ অ্যাপ খুলে **Start new build** > branch `main` > workflow **Android release (signed AAB)** > **Start new build**।
4. শেষে **Artifacts** থেকে `app-release.aab` নামিয়ে Play Console-এ তুলুন। `app-release.apk` সরাসরি ফোনে ইনস্টলের জন্য।

## কী না থাকলে

রিলিজ বিল্ড ইচ্ছা করেই থেমে যায় ("No upload key…"), debug কী দিয়ে সাইন করে না, কারণ Play debug-সাইন করা বান্ডেল নেয় না। শেষ ধাপে বিল্ড যাচাই করে যে বান্ডেলটা আপলোড কী দিয়েই সাইন করা।

## পরে চাইলে

Play-তে সরাসরি আপলোড: Google Play Console থেকে service account তৈরি করে Codemagic-এর **Team settings > Integrations > Google Play**-তে দিন, তারপর `codemagic.yaml`-এর নিচের `publishing` অংশের কমেন্ট তুলে দিন।
