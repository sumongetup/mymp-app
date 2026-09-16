# আমার এমপি — Android app

The mymp.bd reader, in Flutter. Four screens: every member of the thirteenth
parliament, the news and videos written about them, the cabinet, and the
parties. No account, no ads, nothing collected.

```bash
flutter pub get
flutter run                       # a connected phone or emulator
flutter test                      # 8 tests
flutter analyze                   # must be clean before any release build
flutter build appbundle --release # what Play takes
```

## How it gets its data

Everything comes from mymp.bd, read-only and unauthenticated:

| what | route |
|---|---|
| the member list, the parties, the districts | `/api/app/v1/bootstrap` |
| one member's page | `/api/app/v1/mp/<slug>` |
| the cabinet | `/api/app/v1/cabinet` |
| news and videos, the whole house | `/api/app/v1/news` |
| one member's news and videos | `/api/feed/<slug>` |

`bootstrap` is stored on the phone (`shared_preferences`) and shown at once on
the next launch while a fresh copy is fetched behind it; the list is replaced
only when the site's `version` changes. That is what makes the app open
instantly, and open at all with no signal.

The site decides what the app may show, in one file: `src/lib/app/payload.ts`
in the mymp repo. It carries exactly what the website already publishes —
members' home addresses and mobile numbers are in the source data and on
neither.

## The shape of the code

```
lib/
  main.dart        the shell and its four tabs
  theme.dart       the site's palette and type, in one place
  models.dart      what the API answers, parsed defensively
  api.dart         fetching, and the copy kept on the phone
  bn.dart          Bengali numerals, dates and the avatar letter
  widgets.dart     avatar, party chip, member tile, empty and error states
  screens/         members, member, news, cabinet, party, more
```

Two rules worth keeping:

* **Bengali first.** Numbers are Bengali digits (`bn()`), dates are written the
  way a Bengali reader writes them, and the avatar letter skips the honorific:
  মোঃ আবুল হাসনাত is filed under আ. The font is bundled, not fetched.
* **Nothing is collected.** No analytics, no crash reporter, no account, no
  permission beyond `INTERNET`. The Play data-safety answer is "no data
  collected", and every dependency added should keep that true.

## Releasing

The upload key is not in this repository. To build a bundle Play will accept:

1. Create the key once, and keep the file and the passwords safe — losing them
   means never being able to update this app again:

   ```bash
   keytool -genkey -v -keystore mymp-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Write `android/key.properties` (git-ignored):

   ```properties
   storeFile=../../mymp-upload.jks
   storePassword=…
   keyAlias=upload
   keyPassword=…
   ```

3. Raise `version:` in `pubspec.yaml` — the number after `+` must be higher
   than every build already uploaded — then:

   ```bash
   flutter analyze && flutter test && flutter build appbundle --release
   ```

   The bundle lands at `build/app/outputs/bundle/release/app-release.aab`.

Without `key.properties` the release build signs with the debug key so the
command still works on a fresh clone; Play will refuse that bundle.

`docs/play-listing.md` has the store listing, the data-safety answers and the
notes for the reviewer.

## The web build

`flutter run -d chrome` works and is used to look at screens while developing.
It is not a shipped target: on the web the news outlets' own images and the
site's feed route are subject to CORS, so some pictures are blank there and not
on a phone.
