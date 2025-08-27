# 🚀 GLPI 11.x Automated Installation Script

This project provides a **secure and automated Bash script** to install **GLPI 11.x** on a Debian/Ubuntu server.  
The script configures Apache, MariaDB, PHP 8.2, and generates a **self-signed SSL certificate** for HTTPS access.  

---

## ✨ Features

- Automated installation of GLPI **11.0.0-rc3**.
- Dependency check and installation (Apache2, MariaDB, PHP 8.2 and required modules).
- Database setup with user creation.
- Apache virtual host configuration (HTTP & HTTPS).
- Auto-generated **self-signed SSL certificate**.
- Secure GLPI configuration (`config_db.php` with correct permissions).
- Colored log messages for better readability.
- Optional automatic browser opening at the end of installation.
- **Easily adaptable to any server environment** thanks to configurable variables defined at the beginning of the script.

---

## ⚙️ Requirements

- Debian based distribution  
- Root privileges (`sudo` or run as root)  
- Internet connection to download GLPI release  

---

## 📦 Installed Components

- **Web Server**: Apache2 with PHP-FPM  
- **Database**: MariaDB  
- **PHP 8.2** with required modules:
  - `cli`, `fpm`, `mysql`, `curl`, `xml`, `mbstring`, `ldap`, `zip`, `bz2`, `gd`, `intl`, `bcmath`

---

## 🔧 Configuration Variables

At the beginning of the script, you can modify the following variables to adapt the installation to your environment:

```bash
GLPI_VERSION="11.0.0-rc3"          # GLPI version to install
GLPI_DIR="/var/www/glpi"           # Installation directory
DOMAIN_NAME="projet-glpi.lan"      # Apache ServerName
DB_NAME="glpidb"                   # Database name
DB_USER="glpiuser"                 # Database user
````

This makes the script **reusable across different servers** by simply changing a few lines.

---

## 🚀 Installation

1. Clone the repository and enter the directory:

   ```bash
    git clone https://github.com/Ash5134/Automated-GLPI-11.x-Installer-Apache-MariaDB-PHP-SSL-Bash-Script-.git
    cd Automated-GLPI-11.x-Installer-Apache-MariaDB-PHP-SSL-Bash-Script-
    ```

2. Make the script executable:

   ```bash
   chmod +x install_glpi.sh
   ```

3. Run the script as root:

   ```bash
   sudo ./install_glpi.sh
   ```

---

## 🔑 Database Configuration

During execution, you will be prompted to enter a password for the MySQL user (`glpiuser` by default).
The script will then:

* Create the database (`glpidb`)
* Create the user and grant privileges
* Generate the `config_db.php` file under `/var/www/glpi/config/`

---

## 🌐 Access GLPI

Once installation is complete:

* **HTTP**: `http://projet-glpi.lan`
* **HTTPS (self-signed)**: `https://projet-glpi.lan`

The installation wizard will be available at:

👉 `https://projet-glpi.lan/install/install.php`

---

## ⚠️ Notes

* The script generates a **self-signed SSL certificate**, which will trigger a browser warning. For production use, replace it with a trusted certificate (e.g., **Let’s Encrypt**).
* Adapt variables inside the script (`GLPI_VERSION`, `DOMAIN_NAME`, `DB_NAME`, `DB_USER`) before running in production.
* Designed for **educational, testing, and lab environments**.

---

## 📜 License

This project is released under the MIT License.
You are free to use, modify, and distribute it with attribution.

---

## 🙌 Credits

* [GLPI Project](https://glpi-project.org/)
* Inspired by sysadmin automation practices

---

