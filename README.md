# MFU Stall Booking App

Flutter application for vendors to reserve market stalls and upload payment
slips, with an Express and MySQL API for vendor and administrator workflows.
Accounts use a username, phone number, and password. The app does not use email
addresses.

## Requirements

- Node.js and npm
- MySQL
- Flutter SDK

## Backend setup

```sh
cd backend
npm install
cp .env.example .env
```

Edit `backend/.env` with your MySQL settings and a private `JWT_SECRET` of at
least 32 random characters. Do not commit `.env`.

Create the database tables by importing `backend/database.sql` into MySQL. This
script drops and recreates the application tables; use it only for a new or
disposable database. For an existing database, back it up, run
`backend/migrations/000_check_booking_payment_duplicates.sql`, resolve any
reported duplicates, then apply migrations `001` and `002` once each.

Start the API:

```sh
cd backend
npm run dev
```

The server uses `PORT` from `.env`; set it to `5001` to match the Flutter app.
Uploaded slips and profile images are stored under `backend/uploads/` and are
excluded from Git.

## Frontend setup

```sh
cd frontend
flutter pub get
flutter run
```

The API service uses `http://localhost:5001/api/` on macOS and iOS Simulator,
and `http://10.0.2.2:5001/api/` on Android Emulator.

## Create an administrator

There is no public administrator registration route. Create or reset an admin
from a terminal:

```zsh
cd backend
read -s "ADMIN_PASSWORD?Admin password (at least 8 characters): "
export ADMIN_PASSWORD
npm run admin:create
unset ADMIN_PASSWORD
```

Enter a username, display name, full name, and phone when prompted. Vendor
registration in the app creates vendor accounts only.

## Run checks

Backend unit tests use Node's built-in runner and do not connect to MySQL:

```sh
cd backend
npm test
```

Frontend unit tests use mocked HTTP responses:

```sh
cd frontend
flutter test
flutter analyze
```

The backend tests clean up temporary uploaded-file fixtures after each case.

## Project structure

- `backend/controllers`, `models`, `routes`, and `middlewares`: Express MVC API
- `backend/migrations`: incremental schema changes
- `frontend/lib/models`, `controllers`, `services`, and `views`: Flutter MVC app
- `frontend/test` and `backend/test`: unit tests
- `workflow`: UX and architecture references
