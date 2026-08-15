#!/bin/bash
# Zeus ERPNext — Site Initialiser & Demo Data Seeder
# ─────────────────────────────────────────────────────────────────
# Runs once as the `configurator` service.
# Creates the Frappe site, installs all apps, seeds demo data.
# Idempotent: safe to re-run; skips steps that already completed.

set -eo pipefail

BENCH=/home/frappe/frappe-bench
SITE_NAME="${SITE_NAME:-localhost}"
DB_HOST="${DB_HOST:-db}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-root_password}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
REDIS_CACHE="${REDIS_CACHE:-redis-cache:6379}"
REDIS_QUEUE="${REDIS_QUEUE:-redis-queue:6379}"

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║       Zeus — ERPNext Initialiser           ║"
echo "╚════════════════════════════════════════════╝"
echo ""

cd "$BENCH"

# Ensure bench is in PATH (virtualenv)
export PATH="$BENCH/env/bin:$PATH"

# ── Step 1: Wait for MariaDB ──────────────────────────────────────
echo "▶  [1/6] Waiting for MariaDB at $DB_HOST …"
until mysqladmin ping -h "$DB_HOST" -u root --password="$DB_ROOT_PASSWORD" --silent 2>/dev/null; do
    printf "   still waiting …\n"
    sleep 3
done
echo "   ✓ MariaDB is ready."

# ── Step 2: Wait for Redis ────────────────────────────────────────
echo "▶  [2/6] Waiting for Redis …"
REDIS_HOST="${REDIS_CACHE%%:*}"
REDIS_PORT="${REDIS_CACHE##*:}"
until python3 -c "
import socket, sys
try:
    s = socket.create_connection(('$REDIS_HOST', $REDIS_PORT), timeout=2)
    s.sendall(b'PING\r\n')
    r = s.recv(10)
    s.close()
    sys.exit(0 if b'+PONG' in r else 1)
except Exception:
    sys.exit(1)
" 2>/dev/null; do
    printf "   still waiting …\n"
    sleep 2
done
echo "   ✓ Redis is ready."

# ── Step 3: Configure bench globals ───────────────────────────────
echo "▶  [3/6] Configuring bench …"
bench set-config -g db_host       "$DB_HOST"
bench set-config -g redis_cache   "redis://$REDIS_CACHE"
bench set-config -g redis_queue   "redis://$REDIS_QUEUE"
bench set-config -g redis_socketio "redis://$REDIS_QUEUE"
bench set-config -g socketio_port 9000
echo "   ✓ Bench configured."

# ── Step 4: Create site (first run only) ─────────────────────────
echo "▶  [4/6] Checking site '$SITE_NAME' …"
SITE_EXISTS=0
if [ -f "$BENCH/sites/$SITE_NAME/site_config.json" ]; then
    echo "   Site already exists."
    SITE_EXISTS=1
else
    echo "   Creating site '$SITE_NAME' …"
    bench new-site "$SITE_NAME" \
        --db-host          "$DB_HOST"          \
        --db-root-password "$DB_ROOT_PASSWORD" \
        --admin-password   "$ADMIN_PASSWORD"   \
        --no-mariadb-socket                    \
        --set-default 2>&1 | sed 's/^/   /'

    echo "   Installing erpnext …"
    bench --site "$SITE_NAME" install-app erpnext 2>&1 | sed 's/^/   /'
    echo "   ✓ Site created."
fi

# ── Step 5: Ensure required apps are registered and installed ─────
# pip-install in the Dockerfile bypasses `bench get-app`, so apps.txt
# (on the sites volume) may not list hrms/zeus yet. printf starts on a
# fresh line so a missing trailing newline cannot concatenate names.
# HRMS is required (Employee, Attendance, Expense Claim live there in v15).
echo "▶  [5/6] Installing apps …"

register_app() {
    local app="$1"
    local apps_txt="$BENCH/sites/apps.txt"
    if ! grep -q "^${app}$" "$apps_txt" 2>/dev/null; then
        printf '\n%s\n' "$app" >> "$apps_txt"
        echo "   Registered $app in apps.txt"
    fi
}

install_app() {
    local app="$1"
    if [ ! -d "$BENCH/apps/$app" ]; then
        echo "   ERROR: $app is not in the image. Rebuild with: docker compose build"
        exit 1
    fi
    register_app "$app"
    echo "   Installing $app …"
    bench --site "$SITE_NAME" install-app "$app" 2>&1 | sed 's/^/   /'
}

install_app hrms
install_app zeus

if [ "$SITE_EXISTS" = "1" ]; then
    echo "   Migrating site to sync schema …"
    bench --site "$SITE_NAME" migrate --skip-failing 2>&1 | sed 's/^/   /'
fi

echo "   ✓ Apps installed."

# ── Step 6: Seed demo data (always; seeder is idempotent) ─────────
echo "▶  [6/6] Seeding Zeus demo data …"
bench --site "$SITE_NAME" execute zeus.demo_data.seed 2>&1 | sed 's/^/   /'

# Always set host_name so the desk knows where it lives
bench --site "$SITE_NAME" set-config host_name "http://$SITE_NAME"
bench --site "$SITE_NAME" enable-scheduler 2>/dev/null || true

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║  ✓  Zeus is ready!                         ║"
echo "║                                            ║"
echo "║  URL:      http://localhost:8000           ║"
echo "║  Login:    Administrator                   ║"
echo "║  Password: $ADMIN_PASSWORD$(printf '%*s' $((27 - ${#ADMIN_PASSWORD})) '')║"
echo "╚════════════════════════════════════════════╝"
echo ""
