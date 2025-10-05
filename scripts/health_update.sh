#!/usr/bin/env bash
# Health check script - updates nginx homepage with status
set -euo pipefail

STATUS="OK"
DETAILS=()

if ! systemctl is-active --quiet nginx; then
  STATUS="DEGRADED"; DETAILS+=("nginx inactive")
fi

CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/ || echo "000")
if [[ "$CODE" != "200" ]]; then
  STATUS="DEGRADED"; DETAILS+=("curl code=$CODE")
fi

STAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BADGE="$STATUS"
[[ "$STATUS" == "OK" ]] || BADGE="$STATUS (${DETAILS[*]:-})"

sudo awk -v badge="$BADGE" -v stamp="$STAMP" '
  /<div id="status">/ { print "<div id=\\"status\\">Status: <strong>" badge "</strong> @ " stamp "</div>"; skip=1; next }
  { if (!skip) print; else if ($0 ~ /<\\/div>/) skip=0 }
' /usr/share/nginx/html/index.html > /tmp/index.html || true

if ! grep -q "Status:" /tmp/index.html; then
  sudo sed -i "s#</body>#<div id=\\"status\\">Status: <strong>${BADGE}</strong> @ ${STAMP}</div></body>#" /tmp/index.html
fi

sudo install -m 0644 /tmp/index.html /usr/share/nginx/html/index.html
rm -f /tmp/index.html
