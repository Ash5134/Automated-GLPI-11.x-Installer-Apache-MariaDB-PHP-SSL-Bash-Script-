# 🚀 GLPI 11.x Automated Pre-Installation Script (v1.3)

![GLPI](https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/GLPI_Logo.svg/320px-GLPI_Logo.svg.png)
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
