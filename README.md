# TCE Food Court

Flutter food-ordering app using Firebase Authentication, Cloud Firestore and a
local SQLite cache.

## Firebase console setup

1. Create or select the Firebase project referenced by `lib/firebase_options.dart`.
2. Enable **Authentication > Sign-in method > Google**.
3. Enable **Authentication > Sign-in method > Email/Password**.
4. Add the web app's authorized domain under **Authentication > Settings**.
5. For web, the app uses Firebase Auth's Google popup, so no separate
   `google_sign_in` Web Client ID is required. Add the domain where the app is
   hosted to **Authentication > Settings > Authorized domains** and allow
   pop-ups in the browser.
6. Add a `menu_items` collection. Each document should contain `name`,
   `description`, `price`, `imageAsset`, `category`, `rating`, and
   `timesOrdered`.
7. Deploy the included rules from the repository root:

   ```text
   firebase login
   firebase use <your-project-id>
   firebase deploy --only firestore:rules
   ```

   The menu is readable by everyone, while user profiles and orders are
   restricted to the authenticated owner. Email/password and Google accounts
   must use an address ending in `@student.tce.edu`. New account creation also
   collects first name, last name, phone number, student email, and password.
   Orders are stored at
   `users/{uid}/orders/{orderId}`.

## Verify locally

```text
flutter pub get
flutter analyze
flutter test
flutter build web
```

## Local cache

Cloud Firestore stays the source of truth. A SQLite database
(`tce_foodcourt.db`, see `lib/services/local_database.dart`) mirrors the last
successful menu and order reads so the app starts instantly and keeps working
offline:

- A successful menu read refreshes the cache; if Firestore is unreachable the
  cached menu is served instead.
- Placed orders are cached locally, and the cached list is served when Firestore
  cannot be reached. Cached orders are scoped per signed-in user.

If Firestore is unavailable and nothing is cached, the app keeps its bundled
menu catalog. If a signed-in user has no orders, the Orders screen shows its
bundled sample orders. The cache is disabled on web, where sqflite has no
implementation.
