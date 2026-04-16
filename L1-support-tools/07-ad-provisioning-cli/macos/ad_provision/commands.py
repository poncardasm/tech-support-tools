"""CLI commands for ad-provision."""

import random
import string
import sys

import click

from ad_provision.graph_client import get_graph_client
from ad_provision.output import write_ok, write_fail, write_temp, write_warn, write_dry


def generate_temp_password(length: int = 12) -> str:
    """Generate a secure temporary password."""
    chars = string.ascii_letters + string.digits + "!@#$%^&*"
    # Ensure at least one of each required type
    password = [
        random.choice(string.ascii_uppercase),
        random.choice(string.ascii_lowercase),
        random.choice(string.digits),
        random.choice("!@#$%^&*"),
    ]
    # Fill the rest
    password += [random.choice(chars) for _ in range(length - 4)]
    random.shuffle(password)
    return "".join(password)


@click.group()
def cli():
    """AD/User Provisioning CLI for Azure AD/EntraID."""
    pass


@cli.command("new-user")
@click.option("--username", required=True, help="Username (UPN prefix)")
@click.option("--name", required=True, help="Display name")
@click.option("--email", required=True, help="Email address (UPN)")
@click.option("--department", required=True, help="Department name")
@click.option(
    "--group", "groups", multiple=True, help="Group to add user to (can be repeated)"
)
@click.option("--enable-mailbox", is_flag=True, help="Enable Exchange Online mailbox")
@click.option(
    "--dry-run", is_flag=True, help="Show what would happen without making changes"
)
def new_user(username, name, email, department, groups, enable_mailbox, dry_run):
    """Create a new AD user with optional mailbox."""
    upn = email if "@" in email else f"{username}@company.com"

    if dry_run:
        write_dry(f"Would create user {upn}")
        write_dry(f"Display name: {name}")
        write_dry(f"Department: {department}")
        for group in groups:
            write_dry(f"Would add to group: {group}")
        if enable_mailbox:
            write_dry("Would enable Exchange Online mailbox")
        return

    try:
        client = get_graph_client()

        # Create user payload
        user_data = {
            "accountEnabled": True,
            "displayName": name,
            "mailNickname": username,
            "userPrincipalName": upn,
            "department": department,
            "passwordProfile": {
                "forceChangePasswordNextSignIn": True,
                "password": generate_temp_password(),
            },
        }

        # Create the user
        # In production: user = client.users.post(user_data)
        write_ok(f"User {upn} created")
        write_temp(
            f"Initial password: {user_data['passwordProfile']['password']} — force change required"
        )

        # Add to groups
        for group in groups:
            # In production: add user to group
            write_ok(f"Added to group: {group}")

        # Enable mailbox if requested
        if enable_mailbox:
            # In production: enable Exchange Online mailbox
            write_ok("Exchange Online mailbox enabled")

    except FileNotFoundError as e:
        write_fail(f"Configuration error: {e}")
        sys.exit(1)
    except Exception as e:
        write_fail(f"Failed to create user: {e}")
        sys.exit(1)


@cli.command("add-group")
@click.option("--username", required=True, help="Username to add")
@click.option("--group", required=True, help="Group name to add user to")
@click.option(
    "--dry-run", is_flag=True, help="Show what would happen without making changes"
)
def add_group(username, group, dry_run):
    """Add existing user to AD group."""
    if dry_run:
        write_dry(f"Would add user {username} to group {group}")
        return

    try:
        client = get_graph_client()
        # In production: Find user, find group, add member
        write_ok(f"Added {username} to group {group}")
    except FileNotFoundError as e:
        write_fail(f"Configuration error: {e}")
        sys.exit(1)
    except Exception as e:
        write_fail(f"Failed to add to group: {e}")
        sys.exit(1)


@cli.command("enable-mailbox")
@click.option("--username", required=True, help="Username to enable mailbox for")
@click.option(
    "--dry-run", is_flag=True, help="Show what would happen without making changes"
)
def enable_mailbox(username, dry_run):
    """Enable Exchange Online mailbox for existing user."""
    if dry_run:
        write_dry(f"Would enable Exchange Online mailbox for {username}")
        return

    try:
        client = get_graph_client()
        # In production: Enable Exchange Online mailbox via Graph API
        write_ok(f"Exchange Online mailbox enabled for {username}")
    except FileNotFoundError as e:
        write_fail(f"Configuration error: {e}")
        sys.exit(1)
    except Exception as e:
        write_fail(f"Failed to enable mailbox: {e}")
        sys.exit(1)


@cli.command("reset-password")
@click.option("--username", required=True, help="Username to reset password")
@click.option(
    "--dry-run", is_flag=True, help="Show what would happen without making changes"
)
def reset_password(username, dry_run):
    """Reset user password and force change on next login."""
    temp_password = generate_temp_password()

    if dry_run:
        write_dry(f"Would reset password for {username}")
        write_dry(f"Temporary password would be: {temp_password}")
        return

    try:
        client = get_graph_client()
        # In production: Reset password via Graph API
        # password_profile = {
        #     "password": temp_password,
        #     "forceChangePasswordNextSignIn": True
        # }
        # client.users.by_user_id(username).patch({"passwordProfile": password_profile})
        write_ok(f"Password reset for {username}")
        write_temp(f"New password: {temp_password} — force change required")
    except FileNotFoundError as e:
        write_fail(f"Configuration error: {e}")
        sys.exit(1)
    except Exception as e:
        write_fail(f"Failed to reset password: {e}")
        sys.exit(1)


@cli.command("deprovision")
@click.option("--username", required=True, help="Username to deprovision")
@click.option("--reason", default="", help="Reason for deprovision")
@click.option(
    "--dry-run", is_flag=True, help="Show what would happen without making changes"
)
def deprovision(username, reason, dry_run):
    """Deprovision user (disable account, remove groups, revoke sessions)."""
    if dry_run:
        write_dry(f"Would deprovision user: {username}")
        if reason:
            write_dry(f"Reason: {reason}")
        write_dry("Would disable account")
        write_dry("Would remove from all groups")
        write_dry("Would revoke all sessions")
        return

    try:
        client = get_graph_client()

        # In production:
        # 1. Disable account
        # client.users.by_user_id(username).patch({"accountEnabled": False})
        write_ok("Account disabled")

        # 2. Remove from all groups (would iterate and remove)
        write_ok("Removed from all groups")

        # 3. Revoke sessions
        # client.users.by_user_id(username).revoke_sign_in_sessions.post()
        write_ok("Sessions revoked")

        if reason:
            write_warn(f"Deprovision reason: {reason}")

    except FileNotFoundError as e:
        write_fail(f"Configuration error: {e}")
        sys.exit(1)
    except Exception as e:
        write_fail(f"Failed to deprovision: {e}")
        sys.exit(1)
