# Backend guide

This folder contains the Node.js and Express API for StallBookingApp. It currently provides authentication endpoints and an admin API for managing stalls. The Flutter admin screen still uses in-memory sample data; it does not call this API yet.

## How the backend is organized

Requests flow through a small set of layers:

1. `server.js` loads environment settings, checks `JWT_SECRET`, and starts the HTTP server.
2. `src/app.js` creates the Express app, parses JSON request bodies, and mounts API routes. Exporting the app separately lets tests use it without starting a server process.
3. `src/routes/` maps URL paths and HTTP methods to controller functions. Stall routes require a valid JWT and the `admin` role.
4. `src/controllers/` validates request data, calls the model, and turns results into HTTP responses.
5. `src/models/` contains SQL queries. `stallModel.js` reads and writes stalls; `userModel.js` reads and writes users.
6. `src/db.js` creates a MySQL connection pool using values from `.env`.
7. `src/middleware/authMiddleware.js` verifies bearer tokens and checks admin access.
8. `tests/` contains Jest and Supertest API tests. The tests mock the database models, so the test suite does not need a running MySQL server.
9. `schema.sql` creates the database tables used by the API.

## Requirements

- Node.js and npm
- MySQL Server

Check that Node and npm are installed:

```sh
node --version
npm --version
```

These commands print the installed versions and help confirm that the required tools are available.

## Install and configure

Run commands in a terminal from the `backend` directory:

```sh
cd StallBookingApp/backend
npm ci
```

`npm ci` installs the exact dependency versions recorded in `package-lock.json`. Use it for a clean, repeatable setup. (`npm install` is also available if you intentionally want npm to update the lock file.)

Create a local environment file:

```sh
cp .env.example .env
```

`cp` makes a private local configuration file from the example. `.env` is ignored by Git; do not commit real passwords or secrets. Edit `.env` and set the MySQL host, port, username, password, and database to match your machine. `PORT` controls the API port. `JWT_SECRET` must be a random string of at least 32 characters; `JWT_EXPIRES_IN` controls token lifetime.

To generate a suitable secret on systems with OpenSSL:

```sh
openssl rand -hex 32
```

Copy its output into the `JWT_SECRET` setting in `.env`. This command generates random secret material; keep it private.

## Create the MySQL schema

Make sure MySQL is running, then, from `backend`:

```sh
mysql -u root -p < schema.sql
```

`mysql` opens the MySQL command-line client, `-u root` selects the MySQL user, `-p` prompts for its password, and `< schema.sql` sends the schema file to MySQL. Use the MySQL account configured for your environment if it is not `root`. The script creates the `campus_market` database and its `users`, `stalls`, and `bookings` tables. The database name in `.env` should match `DB_NAME` in the script.

## Run the API

From `backend`:

```sh
npm start
```

This runs `node server.js`, which checks the JWT secret and listens on the configured port (3000 by default). Visit `http://localhost:3000/` to check that the server responds. Stop it with `Ctrl+C`.

## Run the tests

From `backend`:

```sh
npm test
```

This runs `jest --runInBand`, executing the auth and stall API tests one at a time. Supertest sends requests to the Express app without needing a separately running server, and the models are mocked so these tests do not need MySQL. The tests cover authorization, field validation, listing and filtering, create/update/delete behavior, duplicate codes, and delete conflicts from upcoming bookings.

## Stall API

All stall endpoints require an `Authorization: Bearer <token>` header with a valid admin JWT. A vendor token receives `403`; a missing or invalid token receives `401`.

| Method and path | Purpose | Success response |
| --- | --- | --- |
| `GET /api/stalls` | List stalls | `200` with `{ "stalls": [...] }` |
| `GET /api/stalls?zone=A&search=food` | Filter by zone and search code/product type | `200` with `{ "stalls": [...] }` |
| `POST /api/stalls` | Create a stall | `201` with `{ "stall": {...} }` |
| `PUT /api/stalls/:id` | Replace a stall's editable fields | `200` with `{ "stall": {...} }` |
| `DELETE /api/stalls/:id` | Delete a stall | `200` with `{ "message": "Stall deleted" }` |

Create and update JSON use these fields:

```json
{
  "code": "A1",
  "zone": "A",
  "size": "3x3 m",
  "price_per_day": 180,
  "product_type": "Food",
  "status": "available"
}
```

The API trims and uppercases the code. Zones must be `A`, `B`, `C`, or `D`. Product types must be `Food`, `Drinks`, `Clothing`, `Accessories`, `Handmade`, or `Other`. Status must be `available` or `unavailable`, and the price must be a positive number. Duplicate stall codes return `409`. Deleting a stall with a pending or approved booking today or later returns `409`; a missing stall returns `404`.

### Try the endpoints with curl

First, register a vendor and log in to receive a token (replace the example password with one at least eight characters long):

```sh
curl -X POST http://localhost:3000/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"demo-vendor","full_name":"Demo Vendor","password":"StrongPass123!"}'

curl -X POST http://localhost:3000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"demo-vendor","password":"StrongPass123!"}'
```

Registration intentionally creates a vendor account, even if a client submits a different role. Stall management is admin-only, so the login response's vendor token cannot call the stall endpoints. Create or promote an admin account through a trusted database/admin setup process; never expose an endpoint that lets a public client choose its own admin role.

After obtaining an admin token, replace `ADMIN_TOKEN` below and try the list and create requests:

```sh
curl http://localhost:3000/api/stalls \
  -H 'Authorization: Bearer ADMIN_TOKEN'

curl -X POST http://localhost:3000/api/stalls \
  -H 'Authorization: Bearer ADMIN_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"code":"A1","zone":"A","size":"3x3 m","price_per_day":180,"product_type":"Food","status":"available"}'
```

`curl` is a command-line HTTP client. `-X` chooses the method, `-H` adds request headers, and `-d` sends the JSON body. These examples are useful for checking the API independently from the Flutter app.

## Common problems

- **`Set JWT_SECRET...` on startup:** set `JWT_SECRET` in `.env` to at least 32 characters.
- **Cannot connect to MySQL:** confirm the server is running and the `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, and `DB_NAME` values are correct.
- **`Unknown database 'campus_market'`:** run the schema command above and confirm `DB_NAME` matches.
- **`401 Unauthorized`:** send a current token as `Authorization: Bearer <token>`.
- **`403 Admin only`:** the token belongs to a vendor. Stall-management routes require an admin token.
- **Stall delete returns `409`:** the stall has a pending or approved booking dated today or later.
