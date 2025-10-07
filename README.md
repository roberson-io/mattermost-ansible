# Mattermost Ansible Deployment

A simple Ansible playbook to deploy Mattermost on a local VM.

## Prerequisites

- Ansible 2.9+ installed on your control machine
- A target VM running Ubuntu 24.04 LTS (or 22.04/20.04)
- SSH access to the target VM
- Sudo privileges on the target VM

## Quick Start

1. **Update the inventory file** with your VM's IP address:
   ```bash
   # Edit inventory/hosts.ini
   # Replace the IP address with your VM's IP
   ```

2. **Test connectivity**:
   ```bash
   ansible all -m ping -i inventory/hosts.ini
   ```

3. **Run the playbook**:
   ```bash
   ansible-playbook -i inventory/hosts.ini deploy.yml
   ```

4. **Access Mattermost**:
   - Open your browser to `http://<your-vm-ip>:8065`
   - Create your admin account on first visit

## What Gets Installed

This MVP deployment includes:
- PostgreSQL database
- Mattermost Team Edition (latest stable)
- Systemd service for Mattermost
- Basic firewall configuration

## Default Configuration

- **Mattermost Port**: 8065
- **Database**: PostgreSQL (local)
- **Mattermost User**: mattermost
- **Installation Path**: /opt/mattermost

## Customization

Edit variables in [deploy.yml](deploy.yml) to customize:
- `mattermost_version`: Version to install
- `mattermost_db_password`: Database password
- `mattermost_site_url`: Your site URL

## Security Note

This is a basic deployment for testing. For production use, consider:
- SSL/TLS configuration
- Nginx/Apache reverse proxy
- Stronger database passwords
- Firewall hardening
- Regular backups
