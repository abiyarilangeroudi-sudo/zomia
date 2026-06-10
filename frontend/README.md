# Zomia Frontend

Flutter MVP application for Zomia.

The first frontend phase is Staff-first:

```text
Staff Login
-> Staff Context
-> Staff Service Panel
-> QR Resolve
-> Register Action
-> Use Reward
```

## Requirements

- Flutter 3.44.1 or newer
- Dart 3.12.1 or newer

## Development

Run from `frontend/`:

```bash
flutter pub get
flutter analyze
flutter test
```

Run the app with the local backend:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

## Language

All visible frontend UI text must be English.
