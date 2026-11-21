# Billetto Events Explorer

## Run locally

With Docker and Compose 2.24 or later, run this from the repo root:

```sh
docker compose up --build
```

Open [localhost:3000](http://localhost:3000). Compose starts Postgres and sets up the database for you.

You don't need an `.env` file to boot. For Billetto API access, copy `.env.example` to `.env`, add your key pair, and run `docker compose up -d` to load it. Keep `.env` out of Git.

```sh
docker compose exec web bin/rails test  # Run tests
docker compose down                     # Stop the app and keep the database
```