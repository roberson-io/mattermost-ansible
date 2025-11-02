#!/usr/bin/env python3
"""Generate environment-specific vault file with secure passwords."""

import sys
from datetime import datetime
from generate_secret import generate_secret

# Constants
ENVIRONMENTS = ["local", "staging", "production"]
SECRET_LENGTH = 32
HEADER_WIDTH = 77
DEFAULT_LDAP_COUNT = 0


def section_header(title):
    """Generate a section header with consistent formatting."""
    return [
        "# " + "=" * HEADER_WIDTH,
        f"# {title}",
        "# " + "=" * HEADER_WIDTH,
        "",
    ]


def main():
    """Generate vault file with environment-specific passwords."""
    # Prompt for LDAP instance count
    try:
        ldap_count = input(
            f"How many OpenLDAP instances per environment? [0-9, default {DEFAULT_LDAP_COUNT}]: "
        ).strip()
        ldap_count = int(ldap_count) if ldap_count else DEFAULT_LDAP_COUNT
    except ValueError:
        print(f"Invalid number, using {DEFAULT_LDAP_COUNT}", file=sys.stderr)
        ldap_count = DEFAULT_LDAP_COUNT

    print("Generating vault file with secure passwords...", file=sys.stderr)

    # Start building the vault content
    lines = [
        "---",
        "# Ansible Vault encrypted secrets",
        f"# Generated on {datetime.now().strftime('%a %b %d %H:%M:%S %Z %Y')}",
        "# All variables prefixed with vault_ are referenced from group_vars files",
        "",
    ]

    # Database passwords section
    lines.extend(section_header("DATABASE PASSWORDS (PostgreSQL)"))
    for env in ENVIRONMENTS:
        lines.extend(
            [
                f"# {env.capitalize()} environment database password",
                f'vault_{env}_db_password: "{generate_secret(SECRET_LENGTH)}"',
                "",
            ]
        )

    # MinIO credentials section
    lines.extend(section_header("MINIO CREDENTIALS (Object Storage)"))
    for env in ENVIRONMENTS:
        lines.extend(
            [
                f"# {env.capitalize()} environment MinIO credentials",
                f'vault_{env}_minio_access_key: "{generate_secret(SECRET_LENGTH)}"',
                f'vault_{env}_minio_secret_key: "{generate_secret(SECRET_LENGTH)}"',
                "",
            ]
        )

    # Keycloak credentials section
    lines.extend(section_header("KEYCLOAK CREDENTIALS (Identity Provider)"))
    for env in ENVIRONMENTS:
        lines.extend(
            [
                f"# {env.capitalize()} environment Keycloak credentials",
                f'vault_{env}_keycloak_admin_password: "{generate_secret(SECRET_LENGTH)}"',
                f'vault_{env}_keycloak_db_password: "{generate_secret(SECRET_LENGTH)}"',
                "",
            ]
        )

    # OpenLDAP credentials section
    if ldap_count > 0:
        lines.extend(section_header("OPENLDAP CREDENTIALS (Directory Services)"))
        lines.extend(
            [
                "# Add more instances as needed (ldap3, ldap4, etc.)",
                "",
            ]
        )

        for env in ENVIRONMENTS:
            for i in range(1, ldap_count + 1):
                lines.extend(
                    [
                        f"# {env.capitalize()} environment - LDAP Instance {i}",
                        f'vault_{env}_ldap{i}_admin_password: "{generate_secret(SECRET_LENGTH)}"',
                        f'vault_{env}_ldap{i}_config_password: "{generate_secret(SECRET_LENGTH)}"',
                        "",
                    ]
                )

    # Redis credentials section
    lines.extend(section_header("REDIS CREDENTIALS (Cache)"))
    for env in ENVIRONMENTS:
        lines.extend(
            [
                f"# {env.capitalize()} environment Redis password",
                f'vault_{env}_redis_password: "{generate_secret(SECRET_LENGTH)}"',
                "",
            ]
        )

    # Write to stdout (will be redirected to file by Makefile)
    print("\n".join(lines))

    return 0


if __name__ == "__main__":
    sys.exit(main())
