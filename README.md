## Google & Firebase ID Token Generator (Flutter Web)

Generate Google and Firebase ID tokens in your browser for testing and backend integration.

- Live: https://imtangim.github.io/google-id-token-generator/
- Source: https://github.com/imtangim/google-id-token-generator

### Features
- Sign in with Google (Firebase Auth)
- View and copy Google ID Token and Firebase ID Token
- Responsive Flutter Web UI

### Development
```bash
flutter pub get
flutter run -d chrome
```

### Build Web
```bash
flutter build web --release --base-href "/google-id-token-generator/" --pwa-strategy=offline-first
```

### Deployment
This repo uses GitHub Actions to build and deploy to GitHub Pages on push to `main`.

### Author
Created by [Imran Tangim](https://github.com/imtangim).
# id_token_generator

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
