# Billetto Events Explorer

## Run locally

With Docker and Compose 2.24 or later, run this from the repo root:

```sh
docker compose up --build
```

Open [localhost:3000](http://localhost:3000). Compose starts Postgres and sets up the database for you.

You don't need an `.env` file to boot. Use [`.env.example`](.env.example) as a template and keep your local `.env` out of Git.

### Import Billetto events

Set `BILLETTO_API_KEYPAIR` in `.env` as `access_key:secret`, then run:

```sh
docker compose up -d
docker compose exec web bin/rails billetto:import
```

Running the import again updates existing listings rather than duplicating them. It skips invalid listings and saves one page at a time, so an API failure doesn't undo earlier pages.

### Set up Clerk

Create a development app in the [Clerk Dashboard](https://dashboard.clerk.com/). Open **API keys**, then choose **JavaScript** under **Quick copy**:

- `CLERK_PUBLISHABLE_KEY`: copy the `pk_test_...` value.
- `CLERK_FRONTEND_API_URL`: copy the HTTPS origin from either script URL, without the `/npm/...` path.
- `CLERK_SECRET_KEY`: copy the `sk_test_...` key for the Ruby SDK. Keep it server-side.

Add these to `.env`, run `docker compose up --build -d`, then open [localhost:3000/sign-up](http://localhost:3000/sign-up). Rails uses the verified Clerk session to show the right account links, so use all three settings to test sign-in and logout.

### Voting and Rails Event Store

Compose runs the Event Store migrations on startup. The store uses JSONB in the same Postgres database as the app, so there's no separate service to run.

- Each signed-in user has one current vote per event. Click the same thumb to undo or the other thumb to switch. Each card shows total likes and total dislikes separately.
- A vote change records a fact with the verified Clerk user ID. A synchronous subscriber updates the current vote in the same transaction. The listing reads counts from the `votes` table, not the event history.

## Tests

```sh
docker compose exec web bin/rails test
```

### Browser tests

```sh
docker compose up --build -d
docker compose exec web bin/rails test:system
```

This runs the listing test in headless Chromium inside `web`. To also test real Clerk sign-up, sign-in, voting, and logout, use a **dedicated Clerk development instance** with test mode, email/password, and email verification codes enabled. Turn off extra required sign-up fields and device verification for that instance. Put its keys in `.env` and run:

```sh
docker compose exec -e RUN_LIVE_CLERK_TEST=1 web bin/rails test:system
```

The live test creates a unique `+clerk_test` user; you can remove it from the Clerk Dashboard afterwards.

Use `docker compose down` to stop the app without deleting the database.