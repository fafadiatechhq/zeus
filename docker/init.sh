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
if [ -f "$BENCH/sites/$SITE_NAME/site_config.json" ]; then
    echo "   Site already exists — running migrate to sync schema …"
    bench --site "$SITE_NAME" migrate --skip-failing 2>&1 | sed 's/^/   /'
else
    echo "   Creating site '$SITE_NAME' …"
    bench new-site "$SITE_NAME" \
        --db-host          "$DB_HOST"          \
        --db-root-password "$DB_ROOT_PASSWORD" \
        --admin-password   "$ADMIN_PASSWORD"   \
        --no-mariadb-socket                    \
        --set-default 2>&1 | sed 's/^/   /'

    # ── Step 5: Install apps ──────────────────────────────────────
    echo "▶  [5/6] Installing apps …"

    echo "   Installing erpnext …"
    bench --site "$SITE_NAME" install-app erpnext 2>&1 | sed 's/^/   /'

    # hrms is bundled in frappe/erpnext:v15; install if available
    echo "   Installing hrms (if available) …"
    bench --site "$SITE_NAME" install-app hrms 2>&1 | sed 's/^/   /' || \
        echo "   hrms not present in image — skipping."

    # Register zeus in apps.txt so bench install-app can find it.
    # (We pip-installed it directly in the Dockerfile, bypassing bench get-app
    #  which is the usual mechanism that writes this file.)
    # printf ensures we always start on a fresh line — plain `echo >>` can
    # concatenate with the previous entry if it lacked a trailing newline,
    # turning "erpnext" + "zeus" into "erpnextzeus".
    APPS_TXT="$BENCH/sites/apps.txt"
    if ! grep -q "^zeus$" "$APPS_TXT" 2>/dev/null; then
        printf '\nzeus\n' >> "$APPS_TXT"
        echo "   Registered zeus in apps.txt"
    fi

    echo "   Installing zeus …"
    bench --site "$SITE_NAME" install-app zeus 2>&1 | sed 's/^/   /'

    # ── Step 6: Seed demo data ────────────────────────────────────
    echo "▶  [6/6] Seeding Zeus demo data …"
    bench --site "$SITE_NAME" execute zeus.demo_data.seed 2>&1 | sed 's/^/   /'

    echo ""
    echo "   ✓ Site setup complete."
fi

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
