# 🚀 GLPI 11.x Automated Pre-Installation Script (v1.3)

![GLPI](data:image/png;base64,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)
![Bash](https://img.shields.io/badge/Script-Bash-green)
![Debian](https://img.shields.io/badge/OS-Debian%2FUbuntu-blue)
![Version](https://img.shields.io/badge/Version-1.3-orange)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

This project provides a **secure and automated Bash script** to install **GLPI 11.x** on Debian/Ubuntu servers.  

**Version 1.3 Highlights**:  
- ✅ **HTTP/2** support for Apache HTTPS  
- ✅ **Self-signed ECDSA SSL certificate** (prime256v1)  
- ✅ **Global `session.cookie_secure` enforcement** in PHP  
- ✅ Idempotent and safe to re-run  

---

## ✨ Features

- Automated installation of GLPI **11.0.0-rc3**
- Dependency check and installation (Apache2, MariaDB, PHP 8.2 and required modules)
- Database setup with user creation
- Apache virtual host configuration:
  - HTTP
  - HTTPS with **HTTP/2**
- Auto-generated **self-signed ECDSA SSL certificate**
- **PHP security hardening** (`session.cookie_secure` enabled globally)
- Secure GLPI configuration (`config_db.php` with correct permissions)
- Colored log messages for readability
- Optional automatic browser opening after installation
- Easily adaptable through configurable variables at the top of the script

---

## ⚙️ Requirements

- Debian-based distribution  
- Root privileges (`sudo` or root)  
- Internet connection to download GLPI release  

---

## 📦 Installed Components

- **Web Server:** Apache2 with PHP-FPM  
- **Database:** MariaDB  
- **PHP 8.2** with modules: `cli`, `fpm`, `mysql`, `curl`, `xml`, `mbstring`, `ldap`, `zip`, `bz2`, `gd`, `intl`, `bcmath`

---

## 🔧 Configuration Variables

Modify these at the beginning of the script:

```bash
GLPI_VERSION="11.0.0-rc3"          # GLPI version to install
GLPI_DIR="/var/www/glpi"           # Installation directory
DOMAIN_NAME="projet-glpi.lan"      # Apache ServerName
DB_NAME="glpidb"                    # Database name
DB_USER="glpiuser"                  # Database user
````

---

## 🚀 Installation

```bash
git clone https://github.com/Ash5134/Automated-GLPI-11.x-Installer-Apache-MariaDB-PHP-SSL-Bash-Script-.git
cd Automated-GLPI-11.x-Installer-Apache-MariaDB-PHP-SSL-Bash-Script-
chmod +x install_glpi.sh
sudo ./install_glpi.sh
```

---

## 🔑 Database Configuration

During installation, enter a password for the MySQL user (`glpiuser` by default).
The script will:

* Create the database (`glpidb`)
* Create the user and grant privileges
* Generate the `config_db.php` file in `/var/www/glpi/config/`

---

## 🌐 Access GLPI

* **HTTP:** `http://projet-glpi.lan`
* **HTTPS (self-signed):** `https://projet-glpi.lan`

Installation wizard URL:
👉 `https://projet-glpi.lan/install/install.php`

---

## 🔒 Security Enhancements (v1.3)

* **Global `session.cookie_secure`**: enforced in `php.ini`, FPM pool, and `.user.ini`
* **HTTPS with HTTP/2** for faster, secure communication
* **ECDSA SSL certificate** (prime256v1) for improved cryptography
* Cache and session files are cleared automatically

---

## ⚠️ Notes

* Self-signed SSL will trigger a browser warning; replace with trusted cert (e.g., Let’s Encrypt) in production.
* Modify variables (`GLPI_VERSION`, `DOMAIN_NAME`, `DB_NAME`, `DB_USER`) as needed.
* Designed for educational, testing, and lab environments.
* Idempotent: safe to re-run for missing configurations or GLPI updates.

---

## 📜 License

MIT License — free to use, modify, and distribute with attribution.

---

## 🙌 Credits

* [GLPI Project](https://glpi-project.org/)
* Inspired by sysadmin automation practices


Veux‑tu que je fasse ça ?
```
