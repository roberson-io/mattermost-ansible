# Mattermost Ansible Deployment

Role-based Ansible playbooks to deploy Mattermost for both local development and production environments.

## Features

- **Multi-distribution support**: Works with Ubuntu, Debian, RHEL, Rocky Linux, CentOS, and Oracle Linux
- **Multi-environment support**: Separate configurations for local VMs and production servers
- **Role-based architecture**: Modular, reusable components
- **Production-ready**: Includes nginx reverse proxy and Let's Encrypt SSL/TLS
- **Separate database tier**: PostgreSQL on dedicated host

## Prerequisites

- Python 3.8+
- Docker (for testing with Molecule)
- Target servers running one of the following Linux distributions:
  - **Ubuntu** 24.04 LTS, 22.04 LTS, or 20.04 LTS
  - **Debian** 12 (Bookworm), 11 (Bullseye), or 10 (Buster)
  - **Rocky Linux** 9 or 8
  - **Red Hat Enterprise Linux (RHEL)** 9, 8, or 7
  - **CentOS** 7+ (legacy support)
  - **Oracle Linux** 7+
- SSH access to target servers
- Sudo privileges on target servers
- **Target server requirements:**
  - Python 3 must be installed
  - For RedHat/Rocky/CentOS: `python3-libselinux` is automatically installed by the playbook
- For production: A registered domain name pointing to your server

## Installation

1. **Clone the repository**

2. **Install dependencies:**
   ```bash
   make install
   ```

   This creates a virtual environment and installs all required packages.

   **Development vs Production:**
   - `requirements.txt` - Flexible version ranges for development
   - `requirements.lock` - Pinned versions for reproducible builds

   For production/CI, install from the lock file:
   ```bash
   pip install -r requirements.lock
   ```

3. **Create your inventory file:**
   ```bash
   # For local development
   cp inventory/local.ini.example inventory/local.ini

   # For production
   cp inventory/production.ini.example inventory/production.ini
   ```

   Then edit the inventory file to match your environment (see Configuration section below).

## Project Structure

```
.
├── site.yml                      # Main playbook
├── inventory/
│   ├── local.ini.example         # Local VM inventory template
│   ├── production.ini.example    # Production server inventory template
│   └── *.ini                     # Your custom inventory files (gitignored)
├── group_vars/
│   ├── local.yml                 # Local environment variables
│   └── production.yml            # Production environment variables
└── roles/
    ├── postgresql/               # Database setup
    ├── mattermost/               # Mattermost application
    ├── nginx/                    # Reverse proxy (production)
    └── certbot/                  # Let's Encrypt SSL (production)
```

## Quick Start

### Local Development

1. **Create and configure your inventory file:**
   ```bash
   cp inventory/local.ini.example inventory/local.ini
   ```

   Edit `inventory/local.ini` with your VM connection details. See [Inventory Configuration](#inventory-configuration) for examples.

2. **Test connectivity:**
   ```bash
   ansible all -m ping -i inventory/local.ini
   ```

3. **Deploy:**
   ```bash
   ansible-playbook -i inventory/local.ini site.yml
   ```

4. **Access:** http://192.168.x.x:8065

### Production Deployment

1. **Create and configure your inventory file:**
   ```bash
   cp inventory/production.ini.example inventory/production.ini
   ```

   Edit `inventory/production.ini` with your server details:
   ```ini
   [database]
   db.example.com ansible_user=ubuntu

   [app]
   app.example.com ansible_user=ubuntu
   ```

2. **Update variables** in [group_vars/production.yml](group_vars/production.yml):
   ```yaml
   nginx_server_name: mattermost.example.com
   certbot_email: admin@example.com
   mattermost_db_password: "STRONG_PASSWORD_HERE"
   ```

3. **Deploy:**
   ```bash
   ansible-playbook -i inventory/production.ini site.yml
   ```

4. **Access:** https://mattermost.example.com

## Configuration

### Inventory Configuration

The inventory file defines how Ansible connects to your servers. Different VM tools and environments use different connection formats.

#### OrbStack (macOS)
```ini
[database]
username@postgresql@orb

[app]
username@mattermost@orb
```

#### Multipass (Linux/macOS/Windows)
```ini
[database]
ubuntu@postgresql.mshome.net

[app]
ubuntu@mattermost.mshome.net
```

#### VirtualBox/Vagrant
```ini
[database]
192.168.56.10 ansible_user=vagrant ansible_ssh_private_key_file=~/.vagrant.d/insecure_private_key

[app]
192.168.56.11 ansible_user=vagrant ansible_ssh_private_key_file=~/.vagrant.d/insecure_private_key
```

#### Standard SSH (Production/Cloud)
```ini
[database]
db.example.com ansible_user=ubuntu ansible_host=10.0.1.10

[app]
app.example.com ansible_user=ubuntu ansible_host=10.0.1.11
```

For more inventory options, see [Ansible inventory documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html).

### Environment Variables

#### Local Environment

- Direct HTTP access on port 8065
- Separate PostgreSQL and Mattermost VMs
- No SSL/TLS

#### Production Environment

- Nginx reverse proxy with HTTP/2
- Let's Encrypt SSL/TLS certificates (auto-renewal)
- HTTPS with HTTP → HTTPS redirect
- Separate database and application servers
- Optimized for performance and security

## Roles

### postgresql
Installs and configures PostgreSQL with:
- Remote connection support
- Database and user creation
- Schema privileges

### mattermost
Installs Mattermost with:
- Systemd service
- Database connection configuration
- User and permission setup

### nginx (production only)
Configures nginx reverse proxy with:
- WebSocket support
- SSL/TLS termination
- Security headers
- Optimized buffering

### certbot (production only)
Manages Let's Encrypt certificates with:
- Automatic certificate generation
- Auto-renewal via cron
- Nginx reload after renewal

## Customization

Edit variables in `group_vars/{environment}.yml`:
- `mattermost_version`: Version to install
- `mattermost_db_password`: Database password
- `nginx_server_name`: Your domain name
- `certbot_email`: Email for Let's Encrypt notifications

## Security Notes

Production deployment includes:
- TLS 1.2/1.3 only
- Modern cipher suites
- OCSP stapling
- Automatic security updates via Let's Encrypt
- Firewall configuration (ufw on Debian/Ubuntu, firewalld on RHEL/Rocky)

**Remember to**:
- Use strong database passwords
- Keep systems updated
- Configure regular backups
- Monitor logs

## Distribution-Specific Notes

### RedHat/Rocky/CentOS/Oracle Linux

**EPEL Repository**: The certbot role automatically installs the EPEL repository for RedHat-family systems, as certbot is not available in the default repositories.

**SELinux**: If SELinux is enabled (default on RHEL/Rocky), you may need to configure policies for nginx and PostgreSQL. The playbook does not currently modify SELinux settings. To allow nginx to connect to the database:

```bash
setsebool -P httpd_can_network_connect_db 1
setsebool -P httpd_can_network_connect 1
```

**PostgreSQL Initialization**: On RHEL-family systems, PostgreSQL requires manual initialization on first install. The playbook handles this automatically with `postgresql-setup --initdb`.

### Debian/Ubuntu

**UFW Firewall**: The playbook configures ufw firewall rules where applicable. If ufw is not installed, the firewall tasks are skipped (ignore_errors: yes).

## Supported Linux Distributions

This playbook has been designed to support all officially supported Mattermost server distributions:

| Distribution | Versions | Status | Notes |
|-------------|----------|--------|-------|
| Ubuntu | 24.04, 22.04, 20.04 LTS | ✅ Tested | Recommended for production |
| Debian | 12, 11, 10 | ✅ Supported | Uses same package manager as Ubuntu |
| Rocky Linux | 9, 8 | ✅ Supported | RHEL-compatible, recommended for RHEL users |
| RHEL | 9, 8, 7 | ✅ Supported | Requires valid RHEL subscription |
| CentOS | 7+ | ⚠️ Legacy | CentOS discontinued, consider Rocky Linux |
| Oracle Linux | 7+ | ✅ Supported | RHEL-compatible |
