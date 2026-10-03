# Book Details App

A simple Flutter app to search books using the free [Open Library API](https://openlibrary.org/developers/api).
Users sign in with Firebase Authentication (email/password or Google).

No state management package is used. The app uses only `StatefulWidget` and `setState`.

## Features

- Sign up, sign in and sign out (email/password and Google)
- Search books by keyword, title or author
- Suggestions while typing
- Sort results and filter by language
- Load more results
- Loading, empty and error messages

## Tech used

- Flutter (Dart)
- Open Library API (`http`)
- Firebase Authentication

## How to run

```bash
flutter pub get
flutter run -d chrome
```

## Author

Shreya Pandey