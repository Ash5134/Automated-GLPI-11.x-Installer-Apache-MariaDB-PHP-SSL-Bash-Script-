#!/bin/bash
set -e

# ===================================================
# Idempotent GLPI 11.x installation script with self-signed SSL
# ===================================================

# ===============================
# CONFIGURATION VARIABLES
# ===============================
GLPI_VERSION="11.0.0-rc3"
GLPI_URL="https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz"
GLPI_DIR="/var/www/glpi"
SSL_DIR="/etc/ssl/glpi"
SITE_CONF="/etc/apache2/sites-available/glpi.conf"
DOMAIN_NAME="projet-glpi.lan"
DB_NAME="glpidb"
DB_USER="glpiuser"

# ===============================
# OUTPUT FORMATTING
# ===============================
log_ok() { echo -e "\e[32m[OK] $1\e[0m"; }
log_error() { echo -e "\e[31m[ERROR] $1\e[0m"; }
log_info() { echo -e "\e[34m[INFO] $1\e[0m"; }

# ===============================
# UTILITY FUNCTIONS
# ===============================
install_if_missing() {
    PKG=$1
    if ! dpkg -s "$PKG" &>/dev/null; then
        log_info "Installing $PKG..."
        apt-get install -y "$PKG"
        log_ok "$PKG installed."
    else
        log_ok "$PKG already installed."
    fi
}

restart_services() {
    systemctl restart php8.2-fpm
    systemctl reload apache2
    log_ok "PHP-FPM and Apache services restarted."
}

enable_session_cookie_secure() {
    log_info "Enabling session.cookie_secure for PHP..."
    PHP_FPM_INI="/etc/php/8.2/fpm/php.ini"
    FPM_POOL="/etc/php/8.2/fpm/pool.d/www.conf"
    USER_INI="$GLPI_DIR/.user.ini"

    # php.ini
    grep -q "^session.cookie_secure" "$PHP_FPM_INI" && \
        sed -i 's/^session.cookie_secure.*/session.cookie_secure = On/' "$PHP_FPM_INI" || \
        echo "session.cookie_secure = On" >> "$PHP_FPM_INI"

    # FPM pool
    grep -q "php_admin_value\[session.cookie_secure\]" "$FPM_POOL" && \
        sed -i 's/php_admin_value\[session.cookie_secure\].*/php_admin_value[session.cookie_secure] = 1/' "$FPM_POOL" || \
        echo "php_admin_value[session.cookie_secure] = 1" >> "$FPM_POOL"

    # .user.ini
    if [ ! -f "$USER_INI" ] || ! grep -q "session.cookie_secure" "$USER_INI"; then
        echo "session.cookie_secure = 1" > "$USER_INI"
        chown www-data:www-data "$USER_INI"
        chmod 644 "$USER_INI"
    fi

    # Clear cache & sessions if exist
    [ -d "$GLPI_DIR/files/_cache" ] && rm -rf "$GLPI_DIR/files/_cache/*"
    [ -d "$GLPI_DIR/files/_sessions" ] && rm -rf "$GLPI_DIR/files/_sessions/*"
    chown -R www-data:www-data "$GLPI_DIR/files/"

    restart_services
    log_ok "session.cookie_secure enabled globally."
}

# ===============================
# STEP FUNCTIONS
# ===============================
update_system() {
    log_info "Updating package repositories..."
    apt-get update && apt-get upgrade -y
    log_ok "System updated."
}

install_dependencies() {
    log_info "Installing required packages..."
    DEPENDENCIES=(
        apache2 mariadb-server mariadb-client wget unzip tar \
        php8.2 php8.2-cli php8.2-fpm php8.2-mysql php8.2-curl php8.2-xml php8.2-mbstring \
        php8.2-ldap php8.2-zip php8.2-bz2 php8.2-gd php8.2-intl php8.2-bcmath
    )
    for pkg in "${DEPENDENCIES[@]}"; do
        install_if_missing "$pkg"
    done
    log_ok "All required packages installed."
}

install_glpi() {
    log_info "Downloading and installing GLPI..."
    cd /tmp
    [ ! -f "glpi-${GLPI_VERSION}.tgz" ] && wget "$GLPI_URL"
    if [ ! -d "$GLPI_DIR" ]; then
        tar -xvzf "glpi-${GLPI_VERSION}.tgz" -C /var/www/
        chown -R www-data:www-data "$GLPI_DIR"
        chmod -R 755 "$GLPI_DIR"
        log_ok "GLPI installed in $GLPI_DIR."
    else
        log_ok "GLPI already installed."
    fi
}

configure_apache_http() {
    log_info "Configuring Apache HTTP..."
    cat > "$SITE_CONF" <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
    DocumentRoot $GLPI_DIR/public
    <Directory $GLPI_DIR/public>
        Require all granted
        AllowOverride All
        Options FollowSymLinks
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php8.2-fpm.sock|fcgi://localhost/"
    </FilesMatch>
    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
EOF
    a2enmod proxy_fcgi setenvif rewrite
    a2dissite 000-default || true
    a2ensite glpi.conf
    systemctl reload apache2
    log_ok "Apache HTTP configured."
}

configure_database() {
    log_info "Configuring MariaDB database..."
    DB_PASS="${DB_PASS:-$(read -s -p "Enter MySQL password for user $DB_USER: " DB_PASS && echo $DB_PASS)}"
    mysql --protocol=socket -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    log_ok "Database and user ensured."

    CONFIG_FILE="$GLPI_DIR/config/config_db.php"
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" <<EOF
<?php
\$DBHOST     = 'localhost';
\$DBPORT     = '';
\$DBNAME     = '$DB_NAME';
\$DBUSER     = '$DB_USER';
\$DBPASS     = '$DB_PASS';
\$DBENCODING = 'utf8mb4';
EOF
        chown www-data:www-data "$CONFIG_FILE"
        chmod 640 "$CONFIG_FILE"
        log_ok "config_db.php created and secured."
    else
        log_ok "config_db.php already exists."
    fi
}

create_ssl_certificate() {
    log_info "Creating self-signed ECDSA SSL certificate..."
    mkdir -p "$SSL_DIR"
    [ ! -f "$SSL_DIR/$DOMAIN_NAME.key" ] && openssl ecparam -name prime256v1 -genkey -noout -out "$SSL_DIR/$DOMAIN_NAME.key"
    [ ! -f "$SSL_DIR/$DOMAIN_NAME.crt" ] && openssl req -x509 -nodes -days 365 \
        -key "$SSL_DIR/$DOMAIN_NAME.key" \
        -out "$SSL_DIR/$DOMAIN_NAME.crt" \
        -subj "/C=FR/ST=Occitanie/L=Sete/O=IT-Connect/OU=IT/CN=$DOMAIN_NAME"
    log_ok "SSL certificate ensured."
}

configure_apache_https() {
    log_info "Configuring Apache HTTPS with HTTP/2..."
    SSL_CONF="/etc/apache2/sites-available/glpi-ssl.conf"
    cat > "$SSL_CONF" <<EOF
<VirtualHost *:443>
    ServerName $DOMAIN_NAME
    DocumentRoot $GLPI_DIR/public
    SSLEngine on
    SSLCertificateFile $SSL_DIR/$DOMAIN_NAME.crt
    SSLCertificateKeyFile $SSL_DIR/$DOMAIN_NAME.key
    Protocols h2 http/1.1
    <Directory $GLPI_DIR/public>
        Require all granted
        AllowOverride All
        Options FollowSymLinks
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php8.2-fpm.sock|fcgi://localhost/"
    </FilesMatch>
    ErrorLog \${APACHE_LOG_DIR}/glpi_ssl_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_ssl_access.log combined
</VirtualHost>
EOF
    a2enmod ssl http2
    a2ensite glpi-ssl.conf
    systemctl reload apache2
    log_ok "Apache HTTPS configured with HTTP/2."
}

open_browser() {
    if command -v xdg-open &>/dev/null; then
        log_info "Opening GLPI in browser..."
        xdg-open "https://$DOMAIN_NAME/install/install.php" >/dev/null 2>&1 &
    else
        log_info "Access GLPI at: https://$DOMAIN_NAME/install/install.php"
    fi
}

# ===============================
# MAIN SCRIPT EXECUTION
# ===============================
update_system
install_dependencies
install_glpi
configure_apache_http
systemctl enable php8.2-fpm
systemctl restart php8.2-fpm
systemctl reload apache2
enable_session_cookie_secure
configure_database
create_ssl_certificate
configure_apache_https
open_browser

log_ok "GLPI installation complete and ready to use."
