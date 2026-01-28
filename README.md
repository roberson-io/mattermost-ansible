# Mattermost Ansible Deployment

Role-based Ansible playbooks to deploy Mattermost for local development, staging, and production environments. This project is still in development and is not officially supported by Mattermost.

## Features

- **Multi-distribution support**: Works with Ubuntu, Debian, RHEL, Rocky Linux, CentOS, and Oracle Linux
- **Multi-environment support**: Separate configurations for local, staging, and production
- **Role-based architecture**: Modular, reusable components
- **TLS**: Includes nginx reverse proxy and Let's Encrypt SSL/TLS
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

   # For staging
   cp inventory/staging.ini.example inventory/staging.ini

   # For production
   cp inventory/production.ini.example inventory/production.ini
   ```

   Then edit the inventory file to match your environment (see Configuration section below).

4. **Set up Ansible Vault for secrets:**
   ```bash
   # Create vault file from example
   cp group_vars/all.yml.example group_vars/all.yml

   # Edit all.yml and set your passwords
   # Then encrypt the file
   ansible-vault encrypt group_vars/all.yml

   # Create a password file (optional, for convenience)
   echo "your_vault_password" > .vault_password
   chmod 600 .vault_password
   ```

   See [Security with Ansible Vault](#security-with-ansible-vault) for more details.

5. **Create your group_vars YAML file:**
   ```bash
   # For local development
   cp group_vars/local.yml.example group_vars/local.yml

   # For staging
   cp group_vars/staging.yml.example group_vars/staging.yml
   
   # For production
   cp group_vars/production.yml.example group_vars/production.yml
   ```

## Project Structure

```
.
├── site.yml                      # Main playbook
├── inventory/
│   ├── local.ini.example         # Local VM inventory template
│   ├── staging.ini.example       # Staging server inventory template
│   ├── production.ini.example    # Production server inventory template
│   └── *.ini                     # Your custom inventory files (gitignored)
├── group_vars/
│   ├── mattermost.yml            # Local environment variables
│   ├── staging.yml               # Staging environment variables
│   ├── production.yml            # Production environment variables
│   ├── all.yml.example           # Vault template for secrets
│   └── all.yml                   # Encrypted secrets (gitignored)
└── roles/
    ├── postgresql/               # Database setup
    ├── mattermost/               # Mattermost application
    ├── nginx/                    # Reverse proxy (staging/production)
    ├── certbot/                  # Let's Encrypt SSL (staging/production)
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
   make deploy-production
   ```

4. **Access:** https://mattermost.example.com

### Staging Deployment

Staging environments are useful for testing changes before deploying to production.

1. **Create and configure your inventory file:**
   ```bash
   cp inventory/staging.ini.example inventory/staging.ini
   ```

   Edit `inventory/staging.ini` with your staging server details.

2. **Update variables** in [group_vars/staging.yml](group_vars/staging.yml):
   ```yaml
   nginx_server_name: staging.mattermost.example.com
   certbot_email: admin@example.com
   ```

3. **Deploy:**
   ```bash
   make deploy-staging
   ```

4. **Access:** https://staging.mattermost.example.com

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

Edit variables in `group_vars/local.yml`, `group_vars/staging.yml`, or `group_vars/production.yml`:
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

## Security with Ansible Vault

Ansible Vault encrypts sensitive information like database passwords and API keys, protecting them from being exposed in version control.

### Initial Setup

**Option 1: Auto-generate secure passwords (recommended):**
```bash
make vault-create-secure   # Creates all.yml with cryptographically secure passwords
make vault-encrypt          # Encrypt it
echo "your_vault_password" > .vault_password && chmod 600 .vault_password
```

**Option 2: Manual password setup:**
```bash
make vault-create           # Creates all.yml from template
nano group_vars/all.yml   # Edit with your passwords
make vault-encrypt          # Encrypt it
echo "your_vault_password" > .vault_password && chmod 600 .vault_password
```

The `.vault_password` file is gitignored and stores your vault encryption password for convenience.

### Using the Vault

The Makefile automatically detects and uses `.vault_password` if it exists. If not, you'll be prompted for the password.

**Deploy with vault (automatic):**
```bash
make deploy-local      # Uses .vault_password if present, otherwise prompts
make deploy-production # Same behavior
```

**Manual playbook execution:**
```bash
# Option 1: Password file (convenient for local dev)
ansible-playbook -i inventory/local.ini site.yml --vault-password-file .vault_password

# Option 2: Prompt for password (more secure for production)
ansible-playbook -i inventory/local.ini site.yml --ask-vault-pass
```

### Managing Vault Secrets

**Using Makefile targets (recommended):**
```bash
make vault-create         # Create all.yml from template
make vault-create-secure  # Create all.yml with auto-generated secure passwords
make vault-encrypt        # Encrypt the vault file
make vault-view           # View encrypted vault contents
make vault-edit           # Edit encrypted vault (decrypts, opens editor, re-encrypts)
make vault-rekey          # Change vault password
make vault-decrypt        # Decrypt vault (WARNING: removes encryption)
```

**Using ansible-vault directly:**
```bash
ansible-vault view group_vars/all.yml     # View encrypted vault
ansible-vault edit group_vars/all.yml     # Edit encrypted vault
ansible-vault rekey group_vars/all.yml    # Change vault password
ansible-vault decrypt group_vars/all.yml  # Decrypt vault (not recommended)
```

### Vault Variables

The vault file ([group_vars/all.yml](group_vars/all.yml)) defines secrets with the `vault_` prefix for each environment:
- `vault_local_db_password` - Database password for local/dev environment
- `vault_staging_db_password` - Database password for staging environment
- `vault_production_db_password` - Database password for production environment

These are referenced in their respective group_vars files:

**In `group_vars/mattermost.yml` (local):**
```yaml
postgresql_db_password: "{{ vault_local_db_password }}"
mattermost_db_password: "{{ vault_local_db_password }}"
```

**In `group_vars/staging.yml`:**
```yaml
postgresql_db_password: "{{ vault_staging_db_password }}"
mattermost_db_password: "{{ vault_staging_db_password }}"
```

**In `group_vars/production.yml`:**
```yaml
postgresql_db_password: "{{ vault_production_db_password }}"
mattermost_db_password: "{{ vault_production_db_password }}"
```

**Note:** Both `postgresql_db_password` and `mattermost_db_password` reference the same vault variable because they represent the same password - the PostgreSQL role creates the database user with this password, and the Mattermost role uses it to connect. Each environment has its own separate password for security isolation.

### Production Best Practices

For production environments:
1. Use `--ask-vault-pass` instead of password files
2. Store vault passwords in a secure password manager
3. Use different vault passwords for different environments
4. Regularly rotate secrets and rekey the vault
5. Consider using external secret management (HashiCorp Vault, AWS Secrets Manager, etc.)

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

**SELinux**: If SELinux is enabled (default on RHEL/Rocky), the playbook automatically configures the necessary SELinux booleans for nginx:
- `httpd_can_network_connect` - Allows nginx to connect to upstream application servers
- `httpd_can_network_connect_db` - Allows nginx to connect to database servers (if needed)

These settings are applied automatically by the nginx role when SELinux is detected as enabled.

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
