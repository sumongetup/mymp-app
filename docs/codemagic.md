# Codemagic দিয়ে অ্যাপ বিল্ড

রিপোজিটরির `codemagic.yaml`-এ দুটো ওয়ার্কফ্লো আছে:

| ওয়ার্কফ্লো | কখন চলে | কী করে |
|---|---|---|
| `android-check` | `main`-এ প্রতিটা push | analyze আর test; কিছু সাইন হয় না |
| `android-release` | `v` দিয়ে শুরু ট্যাগ (যেমন `v1.2.4`) | analyze, test, আপলোড কী দিয়ে সাইন করা AAB আর APK |

## একবারের কাজ

### ১. আপলোড কী তৈরি (নিজের পাসওয়ার্ড দিয়ে)

```bash
"/c/Program Files/Android/Android Studio/jbr/bin/keytool.exe" -genkeypair -v -keystore "C:/Users/User/mymp-upload.jks" -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

পাসওয়ার্ড আর নাম-পরিচয় জিজ্ঞেস করবে। **এই .jks ফাইল আর পাসওয়ার্ড হারালে Play-তে এই অ্যাপ আর আপডেট করা যাবে না।** দুটো জায়গায় ব্যাকআপ রাখুন। ফাইলটা কখনো GitHub-এ দেবেন না।

### ২. Codemagic-এ অ্যাপ যোগ

1. codemagic.io-তে GitHub দিয়ে লগইন করুন (sumongetup অ্যাকাউন্ট)।
2. **Add application** > GitHub > রিপোজিটরি **sumongetup/mymp-app** বাছুন। না দেখালে GitHub-এ Codemagic-কে এই রিপোজিটরির অনুমতি দিন।
3. প্রজেক্টের ধরন **Flutter App**, আর কনফিগারেশন **codemagic.yaml** বাছুন।

### ৩. আপলোড কী Codemagic-এ দিন

**Team settings > Code signing identities > Android keystores > Add keystore**

- Keystore file: `mymp-upload.jks`
- Keystore password, Key alias (`upload`), Key password: আপনার দেওয়া
- **Reference name: `mymp_upload`** (হুবহু এটাই, `codemagic.yaml` এই নাম খোঁজে)

## প্রতিটা রিলিজ

1. `pubspec.yaml`-এ `version: 1.2.4+7`-এর `+`-এর পরের সংখ্যা এক বাড়ান (Play প্রতিবার বড় সংখ্যা চায়)।
2. কমিট করে push করুন, তারপর ট্যাগ:

```bash
git tag v1.2.5
```

```bash
git push origin v1.2.5
```

3. Codemagic-এ `android-release` নিজে চালু হবে। শেষে **Artifacts** থেকে `app-release.aab` নামিয়ে Play Console-এ তুলুন।

চাইলে ট্যাগ ছাড়াও Codemagic-এ **Start new build** চেপে `android-release` বেছে চালানো যায়।

## কী না থাকলে

রিলিজ বিল্ড ইচ্ছা করেই থেমে যায় ("No upload key…"), debug কী দিয়ে সাইন করে না, কারণ Play debug-সাইন করা বান্ডেল নেয় না। শেষ ধাপে বিল্ড যাচাই করে যে বান্ডেলটা আপলোড কী দিয়েই সাইন করা।

## পরে চাইলে

Play-তে সরাসরি আপলোড: Google Play Console থেকে service account তৈরি করে Codemagic-এর **Team settings > Integrations > Google Play**-তে দিন, তারপর `codemagic.yaml`-এর নিচের `publishing` অংশের কমেন্ট তুলে দিন।
