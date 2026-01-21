#!/bin/bash
# Nextcloud Update Script
# Deploy to: /opt/nextcloud/update.sh
#
# Usage:
#   /opt/nextcloud/update.sh
#
# This script:
#   1. Pulls latest Docker images
#   2. Recreates containers with new images
#   3. Runs Nextcloud upgrade process
#   4. Disables maintenance mode

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Nextcloud Update ==="
echo "Started: $(date)"
echo

echo "Pulling latest images..."
docker compose pull

echo
echo "Recreating containers..."
docker compose up -d

echo
echo "Waiting for Nextcloud to be ready..."
sleep 30

echo
echo "Running Nextcloud upgrade..."
docker exec -u www-data nextcloud-app php occ upgrade || true

echo
echo "Disabling maintenance mode..."
docker exec -u www-data nextcloud-app php occ maintenance:mode --off || true

echo
echo "Running database maintenance..."
docker exec -u www-data nextcloud-app php occ db:add-missing-indices || true
docker exec -u www-data nextcloud-app php occ db:add-missing-columns || true
docker exec -u www-data nextcloud-app php occ db:add-missing-primary-keys || true

echo
echo "=== Update Complete ==="
echo "Finished: $(date)"
