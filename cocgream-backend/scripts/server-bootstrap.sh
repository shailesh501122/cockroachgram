#!/usr/bin/env bash
# One-shot Ubuntu server bootstrap for the CockroachGram backend.
#
# Idempotent — safe to re-run.  Run as a sudo-capable user (e.g. `ubuntu`):
#
#   curl -fsSL https://raw.githubusercontent.com/shailesh501122/cockroachgram/main/cocgream-backend/scripts/server-bootstrap.sh | bash
#
# What it does:
#   1. apt update / upgrade
#   2. installs Docker + the compose plugin (official Docker repo)
#   3. adds the current user to the `docker` group
#   4. clones the repo to ~/cockroachgram (or `git pull`s if it already exists)
#   5. writes a default ~/cockroachgram/cocgream-backend/.env from .env.example
#   6. opens firewall ports 22 / 80 (and 443 if ufw is active)
#
# It does NOT start the stack — that happens automatically on the next push
# to `main` via the GitHub Actions deploy workflow.

set -euo pipefail

log() { printf "\n\033[1;33m🪳 %s\033[0m\n" "$*"; }

REPO="https://github.com/shailesh501122/cockroachgram.git"
TARGET="$HOME/cockroachgram"

log "1/5 · apt update"
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

log "2/5 · install Docker (skip if already present)"
if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

if ! groups "$USER" | grep -q docker; then
  log "adding $USER to docker group (re-login required for non-sudo docker)"
  sudo usermod -aG docker "$USER"
fi

log "3/5 · clone or update the repo"
if [ -d "$TARGET/.git" ]; then
  git -C "$TARGET" fetch origin
  git -C "$TARGET" reset --hard origin/main
else
  git clone "$REPO" "$TARGET"
fi

log "4/5 · ensure .env exists"
ENV_FILE="$TARGET/cocgream-backend/.env"
if [ ! -f "$ENV_FILE" ]; then
  cp "$TARGET/cocgream-backend/.env.example" "$ENV_FILE"
  # Generate a real secret key.
  SECRET="$(openssl rand -hex 48)"
  sed -i "s|^DJANGO_SECRET_KEY=.*|DJANGO_SECRET_KEY=${SECRET}|" "$ENV_FILE"
  # Production defaults — debug off, host wildcard (tighten once you have a domain).
  sed -i 's|^DJANGO_DEBUG=.*|DJANGO_DEBUG=false|' "$ENV_FILE"
  echo "🪳  Wrote $ENV_FILE with a generated DJANGO_SECRET_KEY."
  echo "🪳  Edit it to set DJANGO_ALLOWED_HOSTS / S3 creds when you have them."
fi

log "5/5 · firewall"
if command -v ufw >/dev/null 2>&1 && sudo ufw status | grep -q "Status: active"; then
  sudo ufw allow 22/tcp || true
  sudo ufw allow 80/tcp || true
  sudo ufw allow 443/tcp || true
fi

cat <<EOF

🪳  Bootstrap complete.

  Repo:        $TARGET
  Compose:     $TARGET/cocgream-backend/docker-compose.yml + docker-compose.prod.yml
  Env:         $ENV_FILE

Next push to main will deploy automatically via GitHub Actions.

To run the first deploy manually right now (without waiting for CI):

  cd $TARGET/cocgream-backend
  docker compose up -d --build       # builds locally
  docker compose exec api python manage.py seed

API will be on http://<this-host-ip>/  ·  Admin on http://<this-host-ip>/admin/
EOF
