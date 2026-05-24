#!/usr/bin/env bash
# Initial CockroachGram deployment on a fresh Ubuntu host.
# Run after Docker is installed and the user is in the docker group.
set -euo pipefail

log() { printf "\n\033[1;33m🪳 %s\033[0m\n" "$*"; }

REPO="https://github.com/shailesh501122/cockroachgram.git"
TARGET="$HOME/cockroachgram"

# ─── 1. Clone (or update) ────────────────────────────────────────
log "1/5 · clone repo"
if [ -d "$TARGET/.git" ]; then
  git -C "$TARGET" fetch origin
  git -C "$TARGET" reset --hard origin/main
else
  git clone "$REPO" "$TARGET"
fi
cd "$TARGET/cocgream-backend"

# ─── 2. Write .env ───────────────────────────────────────────────
log "2/5 · write .env (prod defaults, generated SECRET_KEY)"
if [ ! -f .env ]; then
  cp .env.example .env
fi
SECRET="$(openssl rand -hex 48)"
PUB_IP="$(curl -s --max-time 3 https://ifconfig.me || echo '')"

set_env() {
  local k=$1 v=$2
  if grep -q "^${k}=" .env; then
    sed -i "s|^${k}=.*|${k}=${v}|" .env
  else
    echo "${k}=${v}" >> .env
  fi
}

set_env DJANGO_SECRET_KEY "${SECRET}"
set_env DJANGO_DEBUG "false"
set_env DJANGO_ALLOWED_HOSTS "*"
set_env DJANGO_CORS_ORIGINS ""
# Bare-IP HTTP: no TLS yet, so flip the cookie/HSTS/redirect knobs off.
set_env DJANGO_SECURE_SSL_REDIRECT "false"
set_env DJANGO_SECURE_COOKIES "false"
set_env DJANGO_HSTS_SECONDS "0"
# CSRF trusted origins — needed for the admin login over plain HTTP.
if [ -n "$PUB_IP" ]; then
  set_env DJANGO_CSRF_TRUSTED_ORIGINS "http://${PUB_IP},https://${PUB_IP}"
fi
# Local filesystem storage for media (saves ~100MB by skipping MinIO).
set_env USE_S3 "false"

# ─── 3. Disable MinIO on this 1GB host ───────────────────────────
log "3/5 · write docker-compose.override.yml (drop MinIO + bind api to :80)"
cat > docker-compose.override.yml <<'YAML'
# Tiny-host override — drops MinIO (saves ~100MB) and exposes API on :80.
services:
  api:
    ports: !override
      - "80:8000"
    depends_on: !override
      db: { condition: service_healthy }
      redis: { condition: service_healthy }
  minio:
    profiles: ["disabled"]   # skip — only starts when --profile disabled
  db:
    ports: !reset []         # don't expose Postgres publicly
YAML

# ─── 4. Build + start ────────────────────────────────────────────
log "4/5 · docker compose up (this builds the api image — first time can take ~5 min)"
docker compose up -d --build

# ─── 5. Wait for healthcheck + seed ──────────────────────────────
log "5/5 · waiting for the API to come up"
for i in $(seq 1 60); do
  if curl -fsS http://localhost:8000/api/health/ >/dev/null 2>&1; then
    echo "🪳 healthy after ${i}s"
    break
  fi
  if [ "$i" = "60" ]; then
    echo "🪳 health check FAILED — recent api logs:"
    docker compose logs --tail=60 api
    exit 1
  fi
  sleep 2
done

log "seeding demo data"
docker compose exec -T api python manage.py seed || true

cat <<EOF

🪳  Deploy complete.

  API:        http://155.248.250.88/api/health/
  Admin:      http://155.248.250.88/admin/   (admin / cockroach-admin)
  Docs:       http://155.248.250.88/api/docs/
  Demo user:  aaravm / cockroach-demo

  Memory:     $(free -h | awk 'NR==2 {print "used " $3 " / " $2 ", swap " $4}')
EOF
