#!/bin/bash
# LAMP Install (Apache + PHP + MariaDB + phpMyAdmin) für Debian 13 (Trixie)
# Fokus: Laravel/Composer Extensions, sichere Defaults, idempotent
# Nutzung:
#   sudo bash install_lamp_debian13.sh
# Optional: Umgebungsvariablen setzen, z.B.:
#   PHP_VERSION=8.4 DB_CREATE=true DB_NAME=app DB_USER=appuser DB_PASS='Str0ngPass!'
#   PHPMYADMIN_ALIAS=/phpmyadmin

set -euo pipefail

# ---------- Konfig ----------
PHP_VERSION="${PHP_VERSION:-8.4}"
PHPMYADMIN_ALIAS="${PHPMYADMIN_ALIAS:-/phpmyadmin}"
DB_CREATE="${DB_CREATE:-false}"         # true/false -> DB & User anlegen
DB_NAME="${DB_NAME:-laravel}"
DB_USER="${DB_USER:-laravel}"
DB_PASS="${DB_PASS:-$(openssl rand -base64 18 | tr -d '=+/_' | cut -c1-20)}"
NONINTERACTIVE="${NONINTERACTIVE:-true}" # apt -y ohne Dialoge
UPDATE_PHP_INI="${UPDATE_PHP_INI:-true}" # sinnvolle Defaults für Laravel
# ----------------------------

if [[ $EUID -ne 0 ]]; then
  echo "Bitte als root oder via sudo ausführen."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo ">>> 1) CD-ROM Quelle deaktivieren (falls vorhanden)…"
sed -i 's|^deb cdrom:|# deb cdrom:|g' /etc/apt/sources.list || true

echo ">>> 2) Debian 13 Repos sicherstellen…"
tee /etc/apt/sources.list >/dev/null <<'EOF'
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
EOF

echo ">>> 3) System aktualisieren…"
apt update
apt -y upgrade

echo ">>> 4) Grundpakete…"
apt -y install ca-certificates curl gnupg lsb-release unzip software-properties-common apt-transport-https

echo ">>> 5) Apache installieren & vorbereiten…"
apt -y install apache2 apache2-utils
a2enmod rewrite headers ssl
systemctl enable --now apache2

echo ">>> 6) PHP ${PHP_VERSION} + Extensions (Laravel/Composer)…"
# Kern + häufige Laravel/Composer-Extensions:
apt -y install \
  php${PHP_VERSION} php${PHP_VERSION}-cli php${PHP_VERSION}-common php${PHP_VERSION}-fpm \
  libapache2-mod-php${PHP_VERSION} \
  php${PHP_VERSION}-mysql php${PHP_VERSION}-pgsql php${PHP_VERSION}-sqlite3 \
  php${PHP_VERSION}-curl php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml php${PHP_VERSION}-zip \
  php${PHP_VERSION}-gd php${PHP_VERSION}-intl php${PHP_VERSION}-bcmath \
  php${PHP_VERSION}-readline php${PHP_VERSION}-opcache php${PHP_VERSION}-soap \
  php${PHP_VERSION}-imagick imagemagick

# (Optional aber oft nützlich)
apt -y install php${PHP_VERSION}-imap php${PHP_VERSION}-xsl || true
php -v

echo ">>> 7) PHP-Konfiguration (empfohlene Defaults für Laravel)…"
if [[ "${UPDATE_PHP_INI}" == "true" ]]; then
  PHP_INI_APACHE="/etc/php/${PHP_VERSION}/apache2/php.ini"
  PHP_INI_CLI="/etc/php/${PHP_VERSION}/cli/php.ini"
  for INI in "$PHP_INI_APACHE" "$PHP_INI_CLI"; do
    [[ -f "$INI" ]] || continue
    sed -ri 's/^memory_limit\s*=.*/memory_limit = 512M/' "$INI"
    sed -ri 's/^upload_max_filesize\s*=.*/upload_max_filesize = 64M/' "$INI"
    sed -ri 's/^post_max_size\s*=.*/post_max_size = 64M/' "$INI"
    sed -ri 's/^max_execution_time\s*=.*/max_execution_time = 120/' "$INI"
    sed -ri 's/^;?date\.timezone\s*=.*/date.timezone = Europe\/Berlin/' "$INI"
  done
fi
systemctl reload apache2

echo ">>> 8) MariaDB installieren…"
apt -y install mariadb-server mariadb-client
systemctl enable --now mariadb

echo ">>> 9) MariaDB absichern (Basis)…"
# Root in Debian/MariaDB nutzt standardmäßig unix_socket-Auth; belassen wir.
# Setzen von sicheren Defaults (Passwort-Policy bleibt Standard).
mysql --protocol=socket -uroot <<'SQL'
-- Anonyme Nutzer entfernen
DELETE FROM mysql.user WHERE User='';
-- root-Remote-Login verhindern
UPDATE mysql.user SET Host='localhost' WHERE User='root' AND Host!='localhost';
-- Test-DB entfernen
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
SQL

if [[ "${DB_CREATE}" == "true" ]]; then
  echo ">>> 10) App-Datenbank & User anlegen…"
  mysql --protocol=socket -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
  echo "    -> DB_NAME=${DB_NAME}, DB_USER=${DB_USER}, DB_PASS=${DB_PASS}"
fi

echo ">>> 11) Composer installieren (global)…"
if ! command -v composer >/dev/null 2>&1; then
  EXPECTED_SIGNATURE="$(curl -s https://composer.github.io/installer.sig)"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
  if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    echo 'ERROR: Invalid Composer installer signature' >&2
    rm -f composer-setup.php
    exit 1
  fi
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet
  rm -f composer-setup.php
fi
composer --version

echo ">>> 12) phpMyAdmin installieren (Paket oder Fallback)…"
set +e
apt -y install phpmyadmin
PKG_STATUS=$?
set -e

if [[ $PKG_STATUS -ne 0 ]]; then
  echo "    Paket phpmyadmin nicht verfügbar – Fallback: Download 'latest' Tarball…"
  mkdir -p /usr/share/phpmyadmin
  TMPD="$(mktemp -d)"
  curl -L -o "${TMPD}/pma.tar.gz" "https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz"
  tar -xzf "${TMPD}/pma.tar.gz" -C "${TMPD}"
  PMADIR="$(find "${TMPD}" -maxdepth 1 -type d -name 'phpMyAdmin-*' | head -n1)"
  rsync -a "${PMADIR}/" /usr/share/phpmyadmin/
  rm -rf "${TMPD}"

  # Konfig & Temp
  mkdir -p /usr/share/phpmyadmin/tmp
  chown -R www-data:www-data /usr/share/phpmyadmin/tmp

  # Apache Alias
  tee /etc/apache2/conf-available/phpmyadmin.conf >/dev/null <<EOF
Alias ${PHPMYADMIN_ALIAS} /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
    Options SymLinksIfOwnerMatch
    DirectoryIndex index.php
    AllowOverride All
    Require all granted
</Directory>

<Directory /usr/share/phpmyadmin/setup>
    Require local
</Directory>
EOF
  a2enconf phpmyadmin
else
  echo "    phpmyadmin Paket installiert."
  # Paket legt meist Alias /phpmyadmin an – falls nicht, setzen wir sicherheitshalber:
  if [[ ! -f /etc/apache2/conf-available/phpmyadmin.conf ]]; then
    tee /etc/apache2/conf-available/phpmyadmin.conf >/dev/null <<EOF
Alias ${PHPMYADMIN_ALIAS} /usr/share/phpmyadmin
<Directory /usr/share/phpmyadmin>
    Options SymLinksIfOwnerMatch
    DirectoryIndex index.php
    AllowOverride All
    Require all granted
</Directory>
EOF
    a2enconf phpmyadmin
  fi
fi

systemctl reload apache2

echo ">>> 13) Apache Default-Host für Laravel tauglich machen (AllowOverride All)…"
AP_DEF="/etc/apache2/sites-available/000-default.conf"
if ! grep -q "AllowOverride All" "$AP_DEF"; then
  sed -ri '/DocumentRoot \/var\/www\/html/a <Directory /var/www/html>\n    AllowOverride All\n    Require all granted\n</Directory>' "$AP_DEF"
  systemctl reload apache2
fi

echo ">>> 14) Fertig!"
echo "PHP $(php -r 'echo PHP_VERSION;') aktiv, Apache läuft: http://$(hostname -I | awk '"'"'{print $1}'"'"')/"
echo "phpMyAdmin erreichbar unter: http://$(hostname -I | awk '{print $1}')${PHPMYADMIN_ALIAS}"
if [[ "${DB_CREATE}" == "true" ]]; then
  echo "DB Zugang:  DB=${DB_NAME}  USER=${DB_USER}  PASS=${DB_PASS}"
fi
