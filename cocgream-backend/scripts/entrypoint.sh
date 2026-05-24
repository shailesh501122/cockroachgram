#!/usr/bin/env bash
# Container entrypoint — run migrations + collectstatic on every boot, then exec the CMD.
set -euo pipefail

echo "🪳 [boot] running migrations…"
python manage.py migrate --noinput

echo "🪳 [boot] collecting static files…"
python manage.py collectstatic --noinput --clear >/dev/null

echo "🪳 [boot] handing off to: $*"
exec "$@"
