#!/usr/bin/env bash
set -euo pipefail

# Install packages
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx awscli jq postgresql-client

systemctl enable nginx
systemctl start nginx

# Fetch DB creds from SSM
DB_ENDPOINT="${db_endpoint}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
# Fetch DB password from SSM parameter store
DB_PASS=$(aws ssm get-parameter --name "${db_pass_param}" --with-decryption --query 'Parameter.Value' --output text)

## Write initial homepage
cat >/var/www/html/index.html <<'HTML'
<!doctype html>
<html>
<head>
  <meta charset=utf-8>
  <title>nginx default</title>
</head>
<body style="font-family: system-ui; margin:40px">
  <h1>nginx is up</h1>
  <p>This is the default nginx site served from a private instance via an ALB.</p>
  <div id=status>Status: <em>initializing...</em></div>
</body>
</html>
HTML

# Setup health check script
install -d -m 0755 /opt/health
cat >/opt/health/health_update.sh <<SH
#!/usr/bin/env bash
set -euo pipefail

# DB connection info
DB_ENDPOINT="${db_endpoint}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASS=\$(aws ssm get-parameter --name "${db_pass_param}" --with-decryption --query 'Parameter.Value' --output text 2>/dev/null || echo "")

# TODO: might want to add retry logic here if SSM is slow

STATUS="OK"
DETAILS=()

if ! systemctl is-active --quiet nginx; then
  STATUS="DEGRADED"; DETAILS+=("nginx inactive")
fi

CODE=\$(curl -s -o /dev/null -w "%%{http_code}" http://127.0.0.1/ || echo "000")
if [[ "\$CODE" != "200" ]]; then
  STATUS="DEGRADED"; DETAILS+=("curl code=\$CODE")
fi

# DB connectivity check
if command -v psql >/dev/null 2>&1 && [[ -n "\$DB_PASS" ]]; then
  PGPASSWORD="\$DB_PASS" psql -h "\$DB_ENDPOINT" -U "\$DB_USER" -d "\$DB_NAME" -tA -c "SELECT 1" >/dev/null 2>&1 || {
    STATUS="DEGRADED"; DETAILS+=("db connect failed")
  }
fi

STAMP=\$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BADGE="\$STATUS"
[[ "\$STATUS" == "OK" ]] || BADGE="\$STATUS (\$${DETAILS[*]:-})"

TMP=\$(mktemp)
awk -v badge="\$BADGE" -v stamp="\$STAMP" '
  /<div id="status">/ { print "<div id=\\"status\\">Status: <strong>" badge "</strong> @ " stamp "</div>"; skip=1; next }
  { if (!skip) print; else if (\$0 ~ /<\\/div>/) skip=0 }
' /var/www/html/index.html > "\$TMP" || true

if ! grep -q "Status:" "\$TMP"; then
  sed -i "s#</body>#<div id=\\"status\\">Status: <strong>\$BADGE</strong> @ \$STAMP</div></body>#" "\$TMP"
fi

install -m 0644 "\$TMP" /var/www/html/index.html
rm -f "\$TMP"
SH

chmod +x /opt/health/health_update.sh

# Systemd service + timer for periodic health updates
cat >/etc/systemd/system/health-update.service <<'UNIT'
[Unit]
Description=Update nginx homepage with health status

[Service]
Type=oneshot
ExecStart=/opt/health/health_update.sh
UNIT

cat >/etc/systemd/system/health-update.timer <<'UNIT'
[Unit]
Description=Run health update every minute

[Timer]
OnBootSec=30s
OnUnitActiveSec=60s
Unit=health-update.service

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable --now health-update.timer
