#!/usr/bin/env bash
set -e

# Pull the latest image for the 'wanderer' service
docker compose \
  -p wanderer \
  --env-file .env \
  -f docker-compose.yml \
  -f reverse-proxy/docker-compose.caddy-gen.yml \
  pull wanderer

# Recreate only the 'wanderer' service container
docker compose \
  -p wanderer \
  --env-file .env \
  -f docker-compose.yml \
  -f reverse-proxy/docker-compose.caddy-gen.yml \
  up -d --force-recreate --no-deps wanderer

