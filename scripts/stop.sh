#!/usr/bin/env bash
set -e

docker compose \
  -p wanderer \
  --env-file .env \
  -f docker-compose.yml \
  -f reverse-proxy/docker-compose.caddy-gen.yml \
  down

