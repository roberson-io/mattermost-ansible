#!/usr/bin/env python3
"""
Download and install official DISA STIG Ansible roles.

This script downloads official DISA STIG Ansible roles from dl.dod.cyber.mil
and extracts them into the roles/ directory for use with the disa-stig wrapper role.

Usage:
    ./scripts/install_disa_stig_roles.py [rhel8|rhel9|ubuntu20|ubuntu22|all]

Note: STIG versions are updated quarterly by DISA. If downloads fail, check
https://public.cyber.mil/stigs/downloads/ for the latest version numbers and
update the STIG_CONFIGS dictionary in this script.
"""

import argparse
import os
import shutil
import sys
import tempfile
import zipfile
from datetime import datetime
from pathlib import Path

import requests


# DISA STIG download configuration
# NOTE: Update these URLs when new STIG versions are released by DISA
# Check https://public.cyber.mil/stigs/downloads/ for latest versions
STIG_CONFIGS = {
    "rhel8": {
        "url": "https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_RHEL_8_V1R14_STIG_Ansible.zip",
        "role_name": "rhel8STIG",
        "version": "V1R14",
    },
    "rhel9": {
        "url": "https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_RHEL_9_V2R5_STIG_Ansible.zip",
        "role_name": "rhel9STIG",
        "version": "V2R5",
    },
    "ubuntu20": {
        "url": "https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_CAN_Ubuntu_20-04_LTS_V1R12_STIG_Ansible.zip",
        "role_name": "ubuntu20STIG",
        "version": "V1R12",
    },
    "ubuntu22": {
        "url": "https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_CAN_Ubuntu_22-04_LTS_V2R5_STIG_Ansible.zip",
        "role_name": "ubuntu22STIG",
        "version": "V2R5",
    },
}


def log_info(message):
    """Print info message."""
    print(f"[INFO] {message}")


def log_error(message):
    """Print error message."""
    print(f"[ERROR] {message}", file=sys.stderr)


def log_success(message):
    """Print success message."""
    print(f"[✓] {message}")


def download_file(url, dest_path):
    """Download a file from URL to destination path using requests."""
    log_info(f"Downloading from {url}...")
    try:
        # Disable SSL verification for dl.dod.cyber.mil (has certificate chain issues)
        response = requests.get(url, verify=False, stream=True, timeout=300)
        response.raise_for_status()

        total_size = int(response.headers.get("content-length", 0))
        downloaded = 0

        with open(dest_path, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        print(f"\rDownloading... {percent:.1f}%", end="", flush=True)

        if total_size > 0:
            print()  # New line after download progress

        return True
    except requests.exceptions.RequestException as e:
        log_error(f"Failed to download: {e}")
        return False


def extract_zip(zip_path, extract_dir):
    """Extract a ZIP file to directory."""
    try:
        with zipfile.ZipFile(zip_path, "r") as zip_ref:
            zip_ref.extractall(extract_dir)
        return True
    except Exception as e:
        log_error(f"Failed to extract {zip_path}: {e}")
        return False


def find_file(directory, pattern):
    """Find first file matching pattern in directory."""
    for root, dirs, files in os.walk(directory):
        for filename in files:
            if pattern in filename.lower():
                return os.path.join(root, filename)
    return None


def install_stig_role(distro, project_root):
    """Download and install a DISA STIG role for the specified distribution."""
    config = STIG_CONFIGS.get(distro)
    if not config:
        log_error(f"Unknown distribution: {distro}")
        return False

    url = config["url"]
    role_name = config["role_name"]
    version = config["version"]
    roles_dir = project_root / "roles"

    log_info(f"Installing official DISA STIG role for {distro} ({version})...")

    # Suppress SSL warnings for dl.dod.cyber.mil
    requests.packages.urllib3.disable_warnings(
        requests.packages.urllib3.exceptions.InsecureRequestWarning
    )

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)

        # Download outer ZIP
        outer_zip = tmp_path / os.path.basename(url)
        if not download_file(url, outer_zip):
            return False

        # Extract outer ZIP
        log_info("Extracting outer archive...")
        outer_extract = tmp_path / f"{distro}_outer"
        if not extract_zip(outer_zip, outer_extract):
            return False

        # Find inner ZIP (contains actual role)
        inner_zip = find_file(outer_extract, "stig-ansible.zip")
        if not inner_zip:
            log_error(f"Could not find inner STIG ansible.zip for {distro}")
            return False

        # Extract inner ZIP
        log_info("Extracting inner archive...")
        inner_extract = tmp_path / f"{distro}_inner"
        if not extract_zip(inner_zip, inner_extract):
            return False

        # Find the role directory
        source_role = inner_extract / "roles" / role_name
        if not source_role.exists():
            log_error(f"Could not find role directory at {source_role}")
            return False

        # Copy role to project roles directory
        dest_role = roles_dir / role_name
        log_info(f"Installing role to {dest_role}...")

        if dest_role.exists():
            shutil.rmtree(dest_role)

        shutil.copytree(source_role, dest_role)

        # Create version marker file
        version_file = dest_role / ".disa-stig-version"
        with open(version_file, "w") as f:
            f.write(f"Distribution: {distro}\n")
            f.write(f"Version: {version}\n")
            f.write(f"Downloaded from: {url}\n")
            f.write(f"Downloaded at: {datetime.now().isoformat()}\n")

        log_success(f"Successfully installed {role_name} ({version})")
        return True


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Download and install official DISA STIG Ansible roles",
        epilog="Note: Check https://public.cyber.mil/stigs/downloads/ for latest STIG versions",
    )
    parser.add_argument(
        "target",
        choices=["rhel8", "rhel9", "ubuntu20", "ubuntu22", "all"],
        help="Distribution to install STIG role for, or 'all' for all distributions",
    )

    args = parser.parse_args()

    # Determine project root (parent of scripts directory)
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    print("=" * 60)
    print("DISA STIG Role Installer")
    print("=" * 60)
    print()

    if args.target == "all":
        success_count = 0
        fail_count = 0

        for distro in ["rhel8", "rhel9", "ubuntu20", "ubuntu22"]:
            if install_stig_role(distro, project_root):
                success_count += 1
            else:
                fail_count += 1
                log_error(f"Failed to install {distro}, continuing...")
            print()

        print()
        log_info(
            f"Installation complete: {success_count} succeeded, {fail_count} failed"
        )

        if fail_count > 0:
            sys.exit(1)
    else:
        if not install_stig_role(args.target, project_root):
            sys.exit(1)

    print()
    log_info(f"DISA STIG roles are now available in: {project_root}/roles")
    print()
    log_info("To use them, set in your group_vars:")
    print("  disa_stig_enabled: true")
    print('  disa_stig_provider: "disa-official"')
    print()


if __name__ == "__main__":
    main()
