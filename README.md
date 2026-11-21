# Billetto Events Explorer

## Run locally

With Docker and Compose 2.24 or later, run this from the repo root:

```sh
docker compose up --build
```

Open [localhost:3000](http://localhost:3000). Compose starts Postgres and sets up the database for you.

You don't need an `.env` file to boot. For the Billetto API key, use [`.env.example`](.env.example) as a template. Keep your local `.env` out of Git.

### Set up Clerk

Create a development app in the [Clerk Dashboard](https://dashboard.clerk.com/). Open **API keys**, then choose **JavaScript** under **Quick copy**:

- `CLERK_PUBLISHABLE_KEY`: copy the `pk_test_...` value.
- `CLERK_FRONTEND_API_URL`: copy the HTTPS origin from either script URL, without the `/npm/...` path.

Add both to `.env`, run `docker compose up -d`, then open [localhost:3000/sign-up](http://localhost:3000/sign-up). You don't need the Clerk secret key for the browser setup.

```sh
docker compose exec web bin/rails test  # Run tests
docker compose down                     # Stop the app and keep the database
```