# Mattermost Ansible Deployment

Role-based Ansible playbooks to deploy Mattermost for both local development and production environments.

## Features

- **Multi-distribution support**: Works with Ubuntu, Debian, RHEL, Rocky Linux, CentOS, and Oracle Linux
- **Multi-environment support**: Separate configurations for local VMs and production servers
- **Role-based architecture**: Modular, reusable components
- **Production-ready**: Includes nginx reverse proxy and Let's Encrypt SSL/TLS
- **Separate database tier**: PostgreSQL on dedicated host
- **Optional Mattermost Calls**: Real-time voice/video with dedicated rtcd service
- **Optional Mattermost Boards**: Project management and kanban boards plugin
- **Enterprise license support**: Automated license activation with mmctl
- **Automated upgrades/downgrades**: Version management with automatic backups

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
│   ├── mattermost.yml            # Local environment variables
│   └── production.yml            # Production environment variables
└── roles/
    ├── postgresql/               # Database setup
    ├── mattermost/               # Mattermost application
    ├── nginx/                    # Reverse proxy (production)
    ├── certbot/                  # Let's Encrypt SSL (production)
    └── rtcd/                     # Real-time communication daemon (optional)
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

Edit variables in `group_vars/mattermost.yml` (for local) or `group_vars/production.yml`:
- `mattermost_version`: Version to install
- `mattermost_db_password`: Database password
- `nginx_server_name`: Your domain name (production only)
- `certbot_email`: Email for Let's Encrypt notifications (production only)

### Enterprise License Configuration

To activate a Mattermost Enterprise license:

1. Place your license file (e.g., `license.mattermost`) in the project root directory
2. Edit `group_vars/mattermost.yml` or `group_vars/production.yml`:
   ```yaml
   mattermost_license_file: "license.mattermost"
   mattermost_service_environment: "test"  # Options: test, production, or dev
   ```
3. Run the deployment playbook

The playbook will automatically:
- Copy the license file to the server
- Upload it using `mmctl`
- Activate Enterprise features

**Note**: The `MM_SERVICEENVIRONMENT` variable must match your license requirements. Check your license agreement for the correct value.

### Mattermost Calls Configuration

To enable voice and video calling with Mattermost Calls:

1. **Add rtcd host to your inventory** (`inventory/local.ini` or `inventory/production.ini`):
   ```ini
   [rtcd]
   username@rtcd@orb  # For local OrbStack
   # OR
   rtcd.example.com ansible_user=ubuntu  # For production
   ```

2. **Enable Calls** in `group_vars/mattermost.yml` or `group_vars/production.yml`:
   ```yaml
   enable_calls: true
   ```

3. **Optional: Customize rtcd settings**:
   ```yaml
   rtcd_version: "v1.2.1"
   rtcd_api_listen_address: "0.0.0.0:8045"
   rtcd_ice_port_udp: 8443
   rtcd_ice_port_tcp: 8443
   ```

4. **Deploy or redeploy**:
   ```bash
   ansible-playbook -i inventory/local.ini site.yml
   ```

The playbook will:
- Install rtcd service on the dedicated host
- Configure firewall rules for API and media ports
- Set up systemd service for rtcd
- Display rtcd URL in deployment output

**Notes:**
- rtcd runs on a separate host from Mattermost for better performance and security
- Default ports: 8045 (API), 8443 (UDP/TCP media)
- STUN/TURN server configuration can be added later if needed for NAT traversal
- For production, configure appropriate firewall rules to allow UDP/TCP traffic on media ports

For more information, see [Mattermost Calls documentation](https://docs.mattermost.com/configure/calls-deployment.html).

### Mattermost Boards Configuration

To enable Mattermost Boards for project management features:

1. **Enable Boards** in `group_vars/mattermost.yml` or `group_vars/production.yml`:
   ```yaml
   mattermost_enable_boards: true
   mattermost_boards_version: "9.1.6"  # Optional: specify version (default is 9.1.6)
   ```

2. **Deploy or redeploy**:
   ```bash
   ansible-playbook -i inventory/local.ini site.yml
   ```

The playbook will:
- Enable plugin support in Mattermost
- Download the Boards plugin from GitHub releases
- Install and enable the plugin using `mmctl`
- Make Boards available in the Mattermost interface

**Notes:**
- Boards appears in the main Mattermost interface after installation
- The plugin ID is `focalboard` (Boards was formerly called Focalboard)
- Requires Mattermost to be running with local mode enabled for `mmctl` access

For more information, see [Mattermost Boards documentation](https://docs.mattermost.com/guides/boards.html).

### Configuration Storage Options

Mattermost supports two methods for storing configuration: **file-based** (default) and **database-based**.

#### File-Based Configuration (Default)

Configuration is stored in `config.json` on the Mattermost server.

**When to use:**
- Single-server deployments
- Development environments
- Simpler backup and version control of configuration

**Setup** (automatic - this is the default):
```yaml
# In group_vars/mattermost.yml or group_vars/production.yml
mattermost_config_storage: "file"  # This is the default
```

#### Database-Based Configuration

Configuration is stored in the PostgreSQL database.

**When to use:**
- High Availability (HA) cluster deployments
- Multiple Mattermost servers sharing configuration
- Dynamic configuration changes via System Console across all nodes

**Benefits:**
- Centralized configuration management
- Immediate sync across HA cluster nodes
- Recommended by Mattermost for production HA deployments

**Setup:**
```yaml
# In group_vars/mattermost.yml or group_vars/production.yml
mattermost_config_storage: "database"
```

Then deploy or redeploy:
```bash
ansible-playbook -i inventory/production.ini site.yml
```

**What happens:**
- Environment file created with `MM_CONFIG` pointing to database
- Configuration automatically applied via `mmctl` commands
- config.json remains but is no longer the primary configuration source
- Changes via System Console are stored in database

**Switching modes:**
Simply change the `mattermost_config_storage` variable and redeploy. The playbook handles the transition automatically.

For more information, see [Mattermost database configuration documentation](https://docs.mattermost.com/administration-guide/configure/configuration-in-your-database.html).

## Upgrading/Downgrading Mattermost

To upgrade or downgrade Mattermost to a different version:

1. Update the version in `group_vars/mattermost.yml` (local) or `group_vars/production.yml`:
   ```yaml
   mattermost_version: "10.12.1"  # Change to desired version
   ```

2. Run the playbook:
   ```bash
   ansible-playbook -i inventory/local.ini site.yml
   ```

The playbook automatically:
- Detects the current version and compares with desired version
- Stops the Mattermost service
- Backs up the database to `/var/backups/mattermost/` (on database host)
- Backs up the application directory to `/opt/mattermost-back-YYYY-MM-DD-HH-mm`
- Downloads and installs the new version (preserving config, data, logs, plugins)
- Restarts the service

**Note:** Users may need to refresh their browsers after an upgrade. The playbook follows the [official Mattermost upgrade documentation](https://docs.mattermost.com/administration-guide/upgrade/upgrading-mattermost-server.html).

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
