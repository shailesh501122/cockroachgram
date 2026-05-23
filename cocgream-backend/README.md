# 🪳 CockroachGram — Backend

> *"Your political voice. Unsilenced."*

Django 5 + DRF backend for the [CockroachGram Flutter app](../cocGream/). Same
stack Instagram runs (Django + Postgres + Redis + S3) — without the
enterprise sprawl.

## What's in the box

| Layer | Choice |
|---|---|
| Framework | **Django 5.1 + Django REST Framework 3.15** |
| Database | **Postgres 16** |
| Cache + future queue | **Redis 7** |
| Object storage | **S3-compatible** — MinIO in dev, swap to AWS S3 / Cloudflare R2 / Backblaze B2 in prod via env vars |
| Auth | **JWT (simple-jwt)** for the app; **Django sessions** for the admin |
| Admin panel | **Django Admin** with custom configs for User / Post / Comment / Notification |
| API docs | **OpenAPI / Swagger** (drf-spectacular) at `/api/docs/` |
| Runtime | **Docker Compose** — `db`, `redis`, `minio`, `api` |
| Pagination | **Cursor** (stable across feed mutations) |
| Throttling | DRF throttles — anon, user, burst, auth-specific |

## Quick start

```bash
cp .env.example .env
docker compose up --build              # api on :8000, admin on :8000/admin
docker compose exec api python manage.py seed
docker compose exec api python manage.py createsuperuser   # if you skipped the seed
```

Then open:

| URL | What |
|---|---|
| <http://localhost:8000/api/docs/> | Swagger UI — every endpoint, try-it-out enabled |
| <http://localhost:8000/admin/> | Django admin (login: `admin` / `cockroach-admin` after seed) |
| <http://localhost:9001/> | MinIO console (login: `cockroach` / `changeme-minio`) |

## Endpoint surface

Matches the 7 Flutter screens:

| Screen | Endpoints |
|---|---|
| Splash + Sign Up | `POST /api/auth/signup/`, `POST /api/auth/login/`, `POST /api/auth/refresh/`, `POST /api/auth/logout/` |
| Feed | `GET /api/posts/?tab=foryou\|following\|state\|trending` |
| Compose | `POST /api/posts/` (multipart for media) |
| Post actions | `POST/DELETE /api/posts/{id}/like/` · `…/repost/` · `…/bookmark/` |
| Comments | `GET/POST /api/posts/{id}/comments/` |
| Profile | `GET /api/users/me/`, `PATCH /api/users/me/`, `GET /api/users/{username}/`, `POST/DELETE /api/users/{username}/follow/` |
| Trending | `GET /api/trending/?window=now\|today\|week\|state` |
| Notifications | `GET /api/notifications/?filter=all\|mentions\|likes\|follows`, `POST /api/notifications/read/`, `GET /api/notifications/unread/` |
| Hashtag drill-down | `GET /api/posts/hashtag/{tag}/` |

All authenticated endpoints expect `Authorization: Bearer <access>`.

## Architecture

```
config/                   Django project (settings, urls, wsgi, asgi)
apps/
  core/                   pagination, throttles, the `seed` command
  users/                  custom User, Follow, signup/login/profile
  posts/                  Post, Hashtag, Comment, Like, Repost, Bookmark + trending
  notifications/          activity feed (signal-driven fanout)
scripts/entrypoint.sh     migrate + collectstatic on every container boot
Dockerfile                multi-stage build (builder + slim runtime, non-root)
docker-compose.yml        db + redis + minio + api
```

### How the pieces talk

- **Signup** writes a `User`, stamps `agreed_manifesto_at`, and returns `{user, access, refresh}`. Member numbers auto-assign from `PK + 42870` to match the splash's `#00042871`.
- **Feed** annotates `likes_count` / `comments_count` / `reposts_count` and three `Exists()` flags (`liked`, `reposted`, `bookmarked`) in one query per page — no N+1.
- **Hashtags** are extracted on every `Post.save()` via a signal (`#MainBhiCockroach` → `Hashtag(tag="mainbhicockroach")`). Trending sorts by `Count(posts)` within the chosen time window.
- **Notifications** fan out via `post_save` signals on `Like`, `Repost`, `Comment`, `Follow` — never blocks the request, easy to swap to Celery later.

## Production checklist

The defaults are production-ready when you flip these:

```env
DJANGO_DEBUG=false
DJANGO_SECRET_KEY=<openssl rand -hex 64>
DJANGO_ALLOWED_HOSTS=api.cockroachgram.in
DJANGO_CORS_ORIGINS=https://app.cockroachgram.in
DATABASE_URL=postgres://…             # managed PG (RDS / Supabase / Neon)
REDIS_URL=redis://…                   # managed Redis
USE_S3=true
AWS_ACCESS_KEY_ID=…                   # real AWS / R2 / B2 creds
AWS_SECRET_ACCESS_KEY=…
AWS_STORAGE_BUCKET_NAME=cockroachgram-prod
AWS_S3_ENDPOINT_URL=                  # empty for AWS, set for R2/B2
AWS_S3_CUSTOM_DOMAIN=cdn.cockroachgram.in
```

When DEBUG is off the settings auto-enable: HSTS (1y), `SECURE_SSL_REDIRECT`, secure cookies, `X-Frame-Options: DENY`, and the proxy SSL header.

### What's *not* in v1 (deliberately)

- Stories with 24h expiry (decorative-only in the design)
- Direct messages
- Search (use hashtag drill-down for now)
- Push notifications (FCM / APNs)
- Background jobs (Celery is wired-ready via the Redis broker — add a `worker` service when needed)

These are clean adds; the schema and signals are designed for them.
