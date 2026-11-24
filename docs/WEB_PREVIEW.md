# Browser preview

The Flutter browser build runs the same screens, navigation, authentication flow,
medicine catalogue, sales cart, stock deduction, local reporting and low-stock
notifications as the Android app.

On web, SQLite is provided by `sqflite_common_ffi_web` and persisted in the
browser's IndexedDB storage for that site origin. This browser database is
separate from the SQLite database on an Android phone; the preview does not
sync data between browser and phone.

The web SQLite adapter is experimental. Camera scanning, device-specific
permissions, native Android behavior, and production pharmacy workflows still
require separate verification on a physical device. Do not enter real patient
or pharmacy data into a public preview.

Build locally:

```sh
flutter pub get
flutter create --platforms=android,web --org com.mydawastore .
dart run sqflite_common_ffi_web:setup
flutter build web --release
```

The GitHub Actions workflow publishes the browser build as a workflow artifact.
