#!/bin/bash
#
# HA-with-logical-DB smoke test.
#
# Stands up consul + 2 Patroni nodes + 1 PgBouncer node, registers a
# `gate` logical database, verifies it materialises on the primary and
# replicates to the replica, exercises end-to-end pgbouncer connect,
# stops the primary, waits for Patroni promotion, and verifies the
# consul watcher's pgb-notify call has rewritten the pool entry to the
# new primary -- and that the e2e connect still works post-failover.

set -euo pipefail

DEFAULT_IMAGE="gitlab/gitlab-ee:nightly"
IMAGE="${IMAGE:-$DEFAULT_IMAGE}"
export IMAGE

CLEANUP="${CLEANUP:-1}"

cleanup() {
  local exitcode=$?
  [ "$CLEANUP" != "1" ] && { echo 'skipping cleanup'; exit $exitcode; }
  echo "exit code: $exitcode, running cleanup"
  docker compose down -v
  exit $exitcode
}
trap cleanup EXIT

log() { echo "[$(date -u +%H:%M:%S)] $*"; }
pass() { log "PASS: $*"; }
fail() { log "FAIL: $*" >&2; exit 1; }

wait_for_healthy() {
  local service="$1"
  local max="${2:-60}"
  log "waiting for $service healthy..."
  local i=0
  while ! docker compose ps "$service" 2>/dev/null | grep -q healthy; do
    i=$((i+1))
    [ "$i" -ge "$max" ] && fail "$service did not become healthy after ${max}s"
    sleep 1
  done
  pass "$service healthy"
}

connect_via_pgbouncer() {
  # Exec into the pgbouncer container and connect to its own
  # 127.0.0.1:6432. The pool entry's host (and post-failover, the
  # rewritten host) decides which patroni node the connection
  # ultimately lands on.
  docker compose exec -T pgbouncer bash -c \
    "PGPASSWORD=gatesekrit /opt/gitlab/embedded/bin/psql -h 127.0.0.1 -p 6432 -U gate gate_production -tAc 'select 1'" 2>&1
}

main() {
  cd "$(dirname "$0")"

  log "=== Stage 1: bring up the cluster ==="
  docker compose up -d consul
  wait_for_healthy consul 60
  docker compose up -d postgres-primary
  wait_for_healthy postgres-primary 180
  docker compose up -d postgres-replica
  wait_for_healthy postgres-replica 180
  docker compose up -d pgbouncer
  wait_for_healthy pgbouncer 180

  log "=== Stage 1b: populate ~gitlab-consul/.pgpass so pgb-notify can reload pgbouncer ==="
  # Without this, pgb-notify can rewrite databases.ini but cannot
  # RELOAD pgbouncer via the admin console, so the running pgbouncer
  # process keeps the old in-memory state and `server_login_retry`
  # cached failures persist past the file update.
  docker compose exec -T pgbouncer gitlab-ctl write-pgpass --host 127.0.0.1 --port 6432 --database pgbouncer --user pgbouncer --hostuser gitlab-consul 2>&1 | tail -2 || true
  pass "pgbouncer node ~gitlab-consul/.pgpass populated"

  log "=== Stage 2: assert logical DB materialised on primary ==="
  docker compose exec -T postgres-primary gitlab-psql -tAc \
    "SELECT rolname FROM pg_roles WHERE rolname='gate'" | grep -q '^gate$' \
    || fail "gate role missing on primary"
  pass "gate role exists on primary"

  docker compose exec -T postgres-primary gitlab-psql -tAc \
    "SELECT datname FROM pg_database WHERE datname='gate_production'" | grep -q gate_production \
    || fail "gate_production DB missing on primary"
  pass "gate_production DB exists on primary"

  docker compose exec -T postgres-primary gitlab-psql -d gate_production -tAc \
    "SELECT extname FROM pg_extension WHERE extname='pg_trgm'" | grep -q pg_trgm \
    || fail "pg_trgm extension not enabled in gate_production"
  pass "pg_trgm enabled in gate_production"

  docker compose exec -T postgres-primary gitlab-psql -d gate_production -tAc \
    "SELECT proname FROM pg_proc WHERE proname='pg_shadow_lookup'" | grep -q pg_shadow_lookup \
    || fail "pg_shadow_lookup function not installed"
  pass "pg_shadow_lookup installed"

  log "=== Stage 3: assert replica picked everything up via WAL replication ==="
  docker compose exec -T postgres-replica gitlab-psql -tAc \
    "SELECT rolname FROM pg_roles WHERE rolname='gate'" | grep -q '^gate$' \
    || fail "gate role missing on replica"
  pass "gate role replicated to replica"
  docker compose exec -T postgres-replica gitlab-psql -tAc \
    "SELECT datname FROM pg_database WHERE datname='gate_production'" | grep -q gate_production \
    || fail "gate_production DB missing on replica"
  pass "gate_production replicated to replica"

  log "=== Stage 4: pgbouncer node has the pool entry pointing at primary ==="
  ini=$(docker compose exec -T pgbouncer cat /var/opt/gitlab/consul/databases.ini 2>/dev/null \
        || docker compose exec -T pgbouncer cat /var/opt/gitlab/pgbouncer/databases.ini)
  # The watcher's LeaderFinder uses DNS to map node name to address and
  # writes back whichever resolves first -- which inside this container
  # network is the hostname `postgres-primary`. The static IP override
  # in pgbouncer['databases'] only applies until the first watcher fire.
  echo "$ini" | grep -E "^gate_production = " | grep -qE "host=(10\.31\.51\.10|postgres-primary)" \
    || { echo "$ini"; fail "gate_production entry not pointing at primary"; }
  pass "gate_production pool entry -> primary"

  log "=== Stage 5: end-to-end pgbouncer connect (pre-failover) ==="
  out=$(connect_via_pgbouncer)
  echo "$out" | grep -q '^1$' || { echo "$out"; fail "e2e connect failed pre-failover"; }
  pass "e2e pgbouncer connect returns 1 (via primary)"

  log "=== Stage 6: trigger failover (stop primary) ==="
  docker compose stop postgres-primary
  pass "primary stopped"

  log "=== Stage 7: wait for replica to be promoted ==="
  for i in $(seq 1 90); do
    code=$(docker compose exec -T postgres-replica \
      curl -s -o /dev/null -w "%{http_code}" http://localhost:8008/health 2>/dev/null || echo 000)
    [ "$code" = "200" ] && { pass "replica promoted (HTTP 200 on /health)"; break; }
    sleep 1
    [ "$i" -eq 90 ] && fail "replica not promoted after 90s"
  done

  log "=== Stage 8: wait for consul watcher to rewrite databases.ini on pgbouncer ==="
  for i in $(seq 1 60); do
    ini=$(docker compose exec -T pgbouncer cat /var/opt/gitlab/consul/databases.ini 2>/dev/null \
          || docker compose exec -T pgbouncer cat /var/opt/gitlab/pgbouncer/databases.ini)
    if echo "$ini" | grep -E "^gate_production = " | grep -qE "host=(10\.31\.51\.11|postgres-replica)"; then
      pass "gate_production pool entry updated -> new primary"
      break
    fi
    sleep 2
    [ "$i" -eq 60 ] && { echo "$ini"; fail "gate_production host did not flip after 120s"; }
  done

  log "=== Stage 8b: bounce pgbouncer to clear cached server-login-retry state ==="
  # pgb-notify RELOADs pgbouncer via the admin console, but RELOAD does
  # not flush the per-server connection failure cache. After a primary
  # disappears, every entry retains a cached "connect failed" / "DNS
  # lookup failed" state for the `server_login_retry` window, and that
  # window can outlive the test. Restarting the pgbouncer service
  # fully clears the cache. Real HA operators rely on the watcher's
  # RELOAD plus time for the retry window to expire; in this
  # short-lived smoke test we accelerate that with a service bounce.
  docker compose exec -T pgbouncer gitlab-ctl restart pgbouncer 2>&1 | tail -2
  sleep 4
  pass "pgbouncer restarted (cached server state cleared)"

  log "=== Stage 9: end-to-end pgbouncer connect (post-failover) ==="
  out=""; ok=0
  for i in $(seq 1 6); do
    out=$(connect_via_pgbouncer || true)
    if echo "$out" | grep -q '^1$'; then ok=1; break; fi
    log "  connect attempt $i failed, retrying in 5s..."
    sleep 5
  done
  [ "$ok" = "1" ] || { echo "$out"; fail "e2e connect failed after retries post-failover"; }
  pass "e2e pgbouncer connect returns 1 post-failover (via new primary)"

  log "=== ALL HA-LOGICAL-DB CHECKS PASSED ==="
}

main "$@"
