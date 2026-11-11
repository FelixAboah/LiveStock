# LiveStock Mobile

Flutter app for the LiveStock poultry farm companion. This project is separate from the existing web prototype.

## Run

From this directory, use the project-bound Puro Flutter SDK:

```powershell
puro flutter pub get
puro flutter run
```

For a browser preview:

```powershell
puro flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8001
```

## Current Scope

Phase 1 is a feed cost calculator. Farmers enter flock size, age, daily feed estimate, available ingredients, inclusion percentages, prices, and a budget. The app checks that the mix totals 100% and calculates batch cost; it does not validate nutritional balance. Data persistence and backend sync are not connected yet.
