#!/usr/bin/env bash
# Riyada production bootstrap — Ubuntu 24.04 LTS
# Usage: sudo ./deploy.sh api.yourdomain.com
set -euo pipefail

DOMAIN="${1:-}"
if [[ -z "$DOMAIN" ]]; then
  echo "Usage: sudo $0 <api-domain>   e.g. api.riyada.iq"
  exit 1
fi

APP_USER="riyada"
APP_DIR="/var/www/riyada"
DATA_DIR="/var/lib/riyada"
ENV_FILE="/etc/riyada/riyada.env"
SERVICE_NAME="riyada"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Updating packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

echo "==> Installing .NET 8 runtime, Nginx, Certbot, UFW"
apt-get install -y curl nginx certbot python3-certbot-nginx ufw postgresql-client

if ! command -v dotnet >/dev/null 2>&1; then
  curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb
  dpkg -i /tmp/packages-microsoft-prod.deb
  apt-get update -y
  apt-get install -y aspnetcore-runtime-8.0
fi

echo "==> Creating application user and directories"
id -u "$APP_USER" &>/dev/null || useradd --system --home "$APP_DIR" --shell /usr/sbin/nologin "$APP_USER"
mkdir -p "$APP_DIR" "$DATA_DIR" /etc/riyada /var/log/riyada
chown -R "$APP_USER:$APP_USER" "$APP_DIR" "$DATA_DIR" /var/log/riyada

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$SCRIPT_DIR/production.env.example" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  echo "Created $ENV_FILE — edit secrets before starting the service."
fi

echo "==> Publishing API (run from repo root on build machine, or copy publish output to $APP_DIR)"
if [[ -f "$SCRIPT_DIR/../SportsApp/Api/Riyada.Api.csproj" ]]; then
  dotnet publish "$SCRIPT_DIR/../SportsApp/Api/Riyada.Api.csproj" -c Release -o "$APP_DIR/publish"
  chown -R "$APP_USER:$APP_USER" "$APP_DIR/publish"
fi

echo "==> Installing systemd unit"
cp "$SCRIPT_DIR/riyada.service" "/etc/systemd/system/${SERVICE_NAME}.service"
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

echo "==> Configuring Nginx"
cp "$SCRIPT_DIR/nginx-riyada.conf" "/etc/nginx/sites-available/riyada"
sed -i "s/api.yourdomain.com/${DOMAIN}/g" "/etc/nginx/sites-available/riyada"
ln -sf "/etc/nginx/sites-available/riyada" "/etc/nginx/sites-enabled/riyada"
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "==> Configuring UFW"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

echo "==> Obtaining TLS certificate (interactive if DNS not ready)"
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "admin@${DOMAIN}" || \
  echo "Certbot failed — ensure DNS points to this server, then run: certbot --nginx -d $DOMAIN"

echo "==> Installing daily database backup cron"
install -m 750 "$SCRIPT_DIR/backup-db.sh" /usr/local/bin/riyada-backup-db
grep -q riyada-backup-db /etc/cron.d/riyada-backup 2>/dev/null || \
  echo "15 2 * * * root /usr/local/bin/riyada-backup-db >> /var/log/riyada/backup.log 2>&1" > /etc/cron.d/riyada-backup

echo "==> Done. Next steps:"
echo "  1. Edit $ENV_FILE (JWT key, PostgreSQL password, FCM credentials)"
echo "  2. Create PostgreSQL: sudo -u postgres createuser riyada && sudo -u postgres createdb riyada -O riyada"
echo "  3. Place Firebase service account JSON at path in Fcm__CredentialsPath"
echo "  4. systemctl restart $SERVICE_NAME"
echo "  5. curl -I https://${DOMAIN}/api/health"
