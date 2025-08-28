#!/bin/bash
set -e

# ===============================
# Script d'installation GLPI 11.x générique, coloré et sécurisé avec SSL auto-signé
# ===============================

# ===============================
# VARIABLES CONFIGURABLES
# ===============================
GLPI_VERSION="11.0.0-rc3"
GLPI_URL="https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz"

# Chemins
GLPI_DIR="/var/www/glpi"                # Dossier d'installation de GLPI
SSL_DIR="/etc/ssl/glpi"                 # Dossier des certificats SSL
SITE_CONF="/etc/apache2/sites-available/glpi.conf"

# Domaine / ServerName
DOMAIN_NAME="projet-glpi.lan"

# Base de données
DB_NAME="glpidb"
DB_USER="glpiuser"

# ===============================
# Couleurs pour affichage
# ===============================
GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

msg_ok() { echo -e "${GREEN}[OK] $1${RESET}"; }
msg_error() { echo -e "${RED}[ERREUR] $1${RESET}"; }
msg_info() { echo -e "${BLUE}[INFO] $1${RESET}"; }

# ===============================
# Fonction pour installer un paquet si absent
# ===============================
install_if_missing() {
    PKG=$1
    if dpkg -s "$PKG" &>/dev/null; then
        msg_ok "$PKG déjà installé."
    else
        msg_info "Installation de $PKG..."
        apt-get install -y "$PKG"
        msg_ok "$PKG installé."
    fi
}

# ===============================
# 1. Mise à jour des dépôts
# ===============================
msg_info "=== [1/8] Mise à jour des dépôts ==="
apt-get update && apt-get upgrade -y
msg_ok "Dépôts mis à jour."

# ===============================
# 2. Installation des dépendances
# ===============================
msg_info "=== [2/8] Installation des dépendances système ==="
DEPENDANCES=(
    apache2 mariadb-server mariadb-client wget unzip tar \
    php8.2 php8.2-cli php8.2-fpm php8.2-mysql php8.2-curl php8.2-xml php8.2-mbstring \
    php8.2-ldap php8.2-zip php8.2-bz2 php8.2-gd php8.2-intl php8.2-bcmath
)
for pkg in "${DEPENDANCES[@]}"; do
    install_if_missing "$pkg"
done
msg_ok "Toutes les dépendances système sont installées."

# ===============================
# 3. Téléchargement et installation de GLPI
# ===============================
msg_info "=== [3/8] Téléchargement et installation de GLPI ==="
cd /tmp
if [ ! -f "glpi-${GLPI_VERSION}.tgz" ]; then
    wget "$GLPI_URL"
fi

if [ ! -d "$GLPI_DIR" ]; then
    tar -xvzf "glpi-${GLPI_VERSION}.tgz" -C /var/www/
fi

chown -R www-data:www-data "$GLPI_DIR"
chmod -R 755 "$GLPI_DIR"
msg_ok "GLPI installé dans $GLPI_DIR."

# ===============================
# 4. Configuration Apache HTTP
# ===============================
msg_info "=== [4/8] Configuration Apache ==="
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

    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
EOF

a2enmod proxy_fcgi setenvif rewrite
a2dissite 000-default
a2ensite glpi.conf
systemctl reload apache2
msg_ok "Apache configuré et site GLPI activé."

# ===============================
# 5. Démarrage des services
# ===============================
msg_info "=== [5/8] Démarrage des services ==="
systemctl enable php8.2-fpm
systemctl restart php8.2-fpm
systemctl reload apache2
msg_ok "Services PHP-FPM et Apache démarrés."

# ===============================
# 6. Configuration de la base de données MariaDB
# ===============================
msg_info "=== [6/8] Configuration de la base de données MariaDB ==="
read -s -p "Mot de passe MySQL pour l'utilisateur $DB_USER : " DB_PASS
echo

mysql --protocol=socket -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
msg_ok "Base de données et utilisateur créés."

if mysql -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" &>/dev/null; then
    msg_ok "Connexion à la base $DB_NAME réussie."
else
    msg_error "Impossible de se connecter à la base $DB_NAME avec l'utilisateur $DB_USER."
    exit 1
fi

# Création de config_db.php
CONFIG_FILE="$GLPI_DIR/config/config_db.php"
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
msg_ok "Fichier config_db.php créé et sécurisé."

# ===============================
# 7. Création certificat SSL auto-signé ECDSA
# ===============================
msg_info "=== [7/8] Création certificat SSL auto-signé ECDSA ==="

# Créer le dossier si nécessaire
mkdir -p "$SSL_DIR"

# Générer la clé ECDSA (courbe prime256v1)
openssl ecparam -name prime256v1 -genkey -noout -out "$SSL_DIR/$DOMAIN_NAME.key"

# Générer le certificat auto-signé
openssl req -x509 -nodes -days 365 \
  -key "$SSL_DIR/$DOMAIN_NAME.key" \
  -out "$SSL_DIR/$DOMAIN_NAME.crt" \
  -subj "/C=FR/ST=Occitanie/L=Sete/O=IT-Connect/OU=IT/CN=$DOMAIN_NAME"

msg_ok "Certificat SSL auto-signé ECDSA créé."

# ===============================
# 8. Configuration Apache HTTPS avec HTTP/2
# ===============================
msg_info "=== [8/8] Configuration Apache HTTPS avec HTTP/2 ==="

# Créer le fichier de configuration SSL pour Apache
cat > "/etc/apache2/sites-available/glpi-ssl.conf" <<EOF
<VirtualHost *:443>
    ServerName $DOMAIN_NAME
    DocumentRoot $GLPI_DIR/public

    SSLEngine on
    SSLCertificateFile $SSL_DIR/$DOMAIN_NAME.crt
    SSLCertificateKeyFile $SSL_DIR/$DOMAIN_NAME.key

    # Activer HTTP/2
    Protocols h2 http/1.1

    <Directory $GLPI_DIR/public>
        Require all granted
        AllowOverride All
        Options FollowSymLinks
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/glpi_ssl_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_ssl_access.log combined
</VirtualHost>
EOF

# Activer les modules nécessaires
a2enmod ssl
a2enmod http2

# Activer le site SSL
a2ensite glpi-ssl.conf

# Recharger Apache pour appliquer les changements
systemctl reload apache2

msg_ok "Apache configuré pour HTTPS avec certificat ECDSA et HTTP/2."

# ===============================
# Ouverture automatique du navigateur si possible
# ===============================
if command -v xdg-open &>/dev/null; then
    msg_info "Ouverture automatique de GLPI dans le navigateur..."
    xdg-open "https://$DOMAIN_NAME/install/install.php" >/dev/null 2>&1 &
else
    msg_info "Accédez à GLPI via : https://$DOMAIN_NAME/install/install.php"
fi

msg_ok "Installation terminée ! GLPI prêt à l'utilisation."
