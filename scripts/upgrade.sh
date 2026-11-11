#!/usr/bin/env bash
set -e

# Pull the latest Wanderer and graph layout service images
docker compose \
  -p wanderer \
  --env-file .env \
  -f docker-compose.yml \
  -f reverse-proxy/docker-compose.caddy-gen.yml \
  pull wanderer layout-service

# Recreate the layout service first and wait until it is ready
docker compose \
  -p wanderer \
  --env-file .env \
  -f docker-compose.yml \
  -f reverse-proxy/docker-compose.caddy-gen.yml \
  up -d --force-recreate --no-deps --wait layout-service

# Recreate the Wanderer service container
docker compose \
  -p wanderer \
  --env-file .env \
  -f docker-compose.yml \
  -f reverse-proxy/docker-compose.caddy-gen.yml \
  up -d --force-recreate --no-deps wanderer

