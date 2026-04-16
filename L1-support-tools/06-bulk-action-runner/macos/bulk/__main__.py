"""CLI entry point for bulk-action-runner."""

import click
from .operations import (
    bulk_password_reset,
    bulk_add_group,
    bulk_enable_mailbox,
    bulk_deprovision,
)


@click.group()
@click.version_option(version=__import__("bulk").__version__, prog_name="bulk-run")
def cli():
    """Bulk Action Runner for Azure AD operations.

    Execute bulk operations against users from a CSV file.
    """
    pass


@cli.command("password-reset")
@click.argument("csv_file", type=click.Path(exists=True))
@click.option(
    "--dry-run", is_flag=True, help="Show what would happen without making changes"
)
@click.option("--report", type=click.Path(), help="Save results to CSV file")
def password_reset_cmd(csv_file, dry_run, report):
    """Reset passwords for all users in CSV."""
    bulk_password_reset(csv_file, dry_run, report)


@cli.command("add-group")
@click.argument("csv_file", type=click.Path(exists=True))
@click.option("--group", required=True, help="Group to add users to")
@click.option(
    "--dry-run", is_flag=True, help="Show what would happen without making changes"
)
@click.option("--report", type=click.Path(), help="Save results to CSV file")
def add_group_cmd(csv_file, group, dry_run, report):
    """Add all users in CSV to a group."""
    bulk_add_group(csv_file, group, dry_run, report)


@cli.command("enable-mailbox")
@click.argument("csv_file", type=click.Path(exists=True))
@click.option(
    "--dry-run", is_flag=True, help="Show what would happen without making changes"
)
@click.option("--report", type=click.Path(), help="Save results to CSV file")
def enable_mailbox_cmd(csv_file, dry_run, report):
    """Enable Exchange Online mailbox per user."""
    bulk_enable_mailbox(csv_file, dry_run, report)


@cli.command("deprovision")
@click.argument("csv_file", type=click.Path(exists=True))
@click.option("--reason", default="", help="Reason for deprovision (for audit log)")
@click.option(
    "--dry-run", is_flag=True, help="Show what would happen without making changes"
)
@click.option("--report", type=click.Path(), help="Save results to CSV file")
def deprovision_cmd(csv_file, reason, dry_run, report):
    """Disable account and remove group memberships."""
    bulk_deprovision(csv_file, reason, dry_run, report)


if __name__ == "__main__":
    cli()
