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

```sh
docker compose exec web bin/rails test  # Run tests
docker compose down                     # Stop the app and keep the database
```