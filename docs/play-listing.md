# Google Play: the listing, the answers, and what a reviewer will look for

Everything here is ready to paste. What only the owner can do is marked **(you)**.

## The entry

| field | value |
|---|---|
| App name | আমার এমপি |
| Package name | `bd.mymp.app` — permanent, cannot be changed after the first upload |
| Default language | বাংলা (বাংলাদেশ) — bn-BD |
| App or game | App |
| Free or paid | Free |
| Category | Books & Reference |
| Tags | Reference, Government |
| Contact email | **(you)** the address you want shown publicly |
| Website | https://mymp.bd |
| Privacy policy | https://mymp.bd/gopaniyota |

On the category: **News & Magazines would be the wrong choice.** Play treats a
news app as a publisher and asks for publisher credentials; this app links to
other people's reporting and publishes none of its own. Books & Reference is
what it is — a reference work about parliament.

## Short description (80 characters max)

```
ত্রয়োদশ সংসদের ৩৪৮ জন সদস্যের তথ্য, সংবাদ ও ভিডিও — এক জায়গায়।
```

## Full description

```
আমার এমপি — বাংলাদেশের ত্রয়োদশ জাতীয় সংসদের সব সদস্যের তথ্য, হাতের মুঠোয়।

আপনার আসনের সংসদ সদস্য কে, তিনি কোন দলের, কী করেন, কোন কমিটিতে আছেন, আর তাঁকে নিয়ে
সংবাদমাধ্যম কী লিখছে — সব এক জায়গায়, বাংলায়।

• ৩৪৮ জন সংসদ সদস্য — নাম, আসন বা জেলা দিয়ে সহজে খুঁজুন
• দল ও জেলা ধরে ছেঁকে দেখুন
• প্রত্যেকের পাতায়: দল, আসন, পেশা, শিক্ষা, জন্মস্থান, সংসদীয় কমিটি ও আগের মেয়াদ
• সংবাদ ও ভিডিও — দেশের সংবাদমাধ্যমের শিরোনাম, প্রতিটির সঙ্গে মূল খবরের লিংক
• মন্ত্রিসভা — কে কোন দায়িত্বে
• দল অনুযায়ী সদস্যতালিকা

তথ্যের সূত্র বাংলাদেশ জাতীয় সংসদের নিজস্ব ওয়েবসাইট ও নির্বাচন কমিশন। সংবাদের ক্ষেত্রে
শুধু শিরোনাম, সংবাদমাধ্যমের নাম ও মূল খবরের লিংক দেখানো হয়; পুরো খবর কপি করা হয় না, পড়তে
চাইলে সংবাদমাধ্যমের নিজস্ব পাতাতেই যেতে হয়।

কোনো অ্যাকাউন্ট লাগে না। কোনো ব্যক্তিগত তথ্য সংগ্রহ করা হয় না, কোনো বিজ্ঞাপন নেই।
সদস্যতালিকাটি ফোনেই রাখা হয়, তাই নেটওয়ার্ক দুর্বল হলেও অ্যাপ খোলে।

ভুল চোখে পড়লে জানান: mymp.bd/jogajog

ওয়েবসাইট: mymp.bd
```

## Data safety

Answer **"No, this app does not collect or share any user data."** It is true:
there is no account, no analytics, no crash reporter, no advertising id, and
the only Android permission is `INTERNET`. The one thing stored on the phone is
a copy of the public member list, which is app content, not user data.

- Is all user data encrypted in transit? — Not applicable; nothing is sent. The
  app's own requests are all HTTPS.
- Do you provide a way to delete data? — Not applicable; nothing is held.

## Content rating

Fill in the IARC questionnaire truthfully: no violence, no sexual content, no
profanity, no gambling, no user-to-user communication, no location sharing,
no purchases. It rates 3+ / everyone.

The questionnaire asks whether the app contains **news or user-generated
content**: answer that it links to news published by third parties and hosts
none. Rating stays "everyone".

## Ads

No ads. Say so.

## App access

Declare **all functionality is available without restrictions** — there is no
login of any kind, so no credentials need to be given to the reviewer.

## Notes for the reviewer (the "Instructions" box)

```
This app is a reader for mymp.bd, a public-interest reference site about the
members of the Bangladesh parliament. All content comes from public sources:
the parliament secretariat's own website and the Election Commission. There is
no login, no account, and no user data of any kind is collected.

News: the app shows only headlines, the outlet's name and a link. Tapping a
headline opens the outlet's own page in the browser. No article text is copied
or hosted.

Photographs of members are the ones the parliament secretariat publishes.
```

## Graphics **(you)**

| asset | size | notes |
|---|---|---|
| App icon | 512×512 PNG, no transparency | the mymp mark, already in `assets/images/logo.png` |
| Feature graphic | 1024×500 PNG/JPG | required; a plain green band with the app name works |
| Phone screenshots | at least 2, up to 8; 16:9 or 9:16, min 320px | `docs/screenshots/` holds ready-made ones |

## Before the first upload

1. Create the upload key and `android/key.properties` (see the README) — **(you)**,
   because only you should ever hold that password.
2. `flutter analyze && flutter test` — both clean.
3. `flutter build appbundle --release`.
4. Upload `build/app/outputs/bundle/release/app-release.aab` to a **closed
   test** track first. Play requires a period of closed testing on new personal
   developer accounts before production is opened; starting there costs
   nothing and avoids a rejection on that rule alone.
5. Fill in the listing above, the data-safety form and the content rating.
6. Send for review.

## After it is live

- Every later upload needs a higher `version:` build number in `pubspec.yaml`.
- The site's API is versioned at `/api/app/v1`. Do not change a field's meaning
  under a phone that is already out there; add a field instead, and let old
  versions ignore it.
