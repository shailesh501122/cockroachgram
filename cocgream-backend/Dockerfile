# ===== Stage 1: builder =====
FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev \
 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --user -r requirements.txt

# ===== Stage 2: runtime =====
FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/home/app/.local/bin:$PATH" \
    DJANGO_SETTINGS_MODULE=config.settings

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 curl \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --create-home --shell /bin/bash app

USER app
WORKDIR /app

COPY --from=builder --chown=app:app /root/.local /home/app/.local
COPY --chown=app:app . .

RUN chmod +x scripts/entrypoint.sh

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://localhost:8000/api/health/ || exit 1

ENTRYPOINT ["scripts/entrypoint.sh"]
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3", "--access-logfile", "-"]
