# 🪳 cockroachgram

> *"Your political voice. Unsilenced."*

Monorepo for **CockroachGram** — a political social-media app concept for India's youth.

| Folder | What | Stack |
|---|---|---|
| [`cocGream/`](cocGream/) | Mobile app (Android, iOS, Web, Windows) | Flutter 3.38 / Dart 3.10 |
| [`cocgream-backend/`](cocgream-backend/) | API + Admin | Django 5.1 + DRF + Postgres + Redis + S3-compatible storage |

## Quick start

### 1. Backend

```bash
cd cocgream-backend
cp .env.example .env
docker compose up --build                          # api on :8000, admin on :8000/admin
docker compose exec api python manage.py seed     # demo content + admin user
```

Defaults: admin login `admin / cockroach-admin`, demo users `aaravm / cockroach-demo`.
API docs: <http://localhost:8000/api/docs/>.

### 2. App

```bash
cd cocGream
flutter pub get
flutter run -d <device>     # Android, iOS sim, Chrome, Windows
```

For a physical Android phone talking to a local backend: `adb reverse tcp:8000 tcp:8000` first.
Override the API host with `--dart-define=API_BASE_URL=https://api.example.com/api`.

## Tooling

```bash
# App
flutter analyze && flutter test && flutter build apk --debug

# Backend (inside the api container)
python manage.py migrate
python manage.py createsuperuser
python manage.py seed --wipe       # reset to demo state
```

## Architecture (top level)

```
[ Flutter app ] ──HTTPS/JWT──▶ [ Django + DRF ] ──▶ [ Postgres ]
                                       │            └─▶ [ Redis ]
                                       └─▶ [ S3-compatible bucket ]
                                                (MinIO in dev, R2/S3/B2 in prod)
```

JWT access tokens are persisted in the platform keystore (Keychain / EncryptedSharedPreferences) and auto-refreshed on 401.

## License

TBD.
