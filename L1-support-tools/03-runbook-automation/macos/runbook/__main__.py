"""Runbook Automation CLI entry point."""

import signal
import sys

import click

from .executor import execute_runbook, show_runbook_steps
from .indexer import list_runbooks, search_runbooks
from .state import load_state, save_state, ExecutionContext


@click.group()
@click.version_option(version=__import__("runbook").__version__, prog_name="runbook")
def cli():
    """Runbook Automation CLI.

    Execute markdown-based runbooks with embedded shell commands.
    """
    pass


@cli.command()
@click.argument("file", type=click.Path(exists=True))
@click.option("--from-step", default=1, help="Start from step N", type=int)
@click.option("--resume", is_flag=True, help="Resume from last failed step")
@click.option("--dry-run", is_flag=True, help="Show commands without executing")
@click.option("--show-steps", is_flag=True, help="Show steps without executing")
def run(file, from_step, resume, dry_run, show_steps):
    """Execute a runbook."""
    if show_steps:
        show_runbook_steps(file)
        return

    if resume:
        state = load_state(file)
        from_step = state.get("current_step", 1)
        click.echo(f"Resuming from step {from_step}")

    # Use ExecutionContext for proper state management and Ctrl+C handling
    try:
        with ExecutionContext(file, from_step) as ctx:
            success = execute_runbook(file, from_step, dry_run)
            if not success:
                sys.exit(1)
    except KeyboardInterrupt:
        # ExecutionContext handles state saving on interrupt
        sys.exit(130)  # Standard exit code for Ctrl+C
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


@cli.command(name="list")
@click.option("--category", help="Filter by category")
@click.option("--directory", default="./runbooks", help="Runbooks directory")
def list_command(category, directory):
    """List all runbooks."""
    runbooks = list_runbooks(directory=directory, category=category)
    if not runbooks:
        click.echo("No runbooks found.")
        return

    click.echo(f"{'Name':<30} {'Category':<20} {'Path'}")
    click.echo("-" * 80)
    for rb in runbooks:
        click.echo(f"{rb['name']:<30} {rb['category']:<20} {rb['path']}")


@cli.command()
@click.argument("query")
@click.option("--directory", default="./runbooks", help="Runbooks directory")
def search(query, directory):
    """Search runbooks."""
    results = search_runbooks(query, directory=directory)
    if not results:
        click.echo(f'No runbooks found matching "{query}".')
        return

    click.echo(f"Found {len(results)} result(s) for '{query}':")
    click.echo("-" * 80)
    for rb in results:
        click.echo(f"{rb['name']:<30} ({rb['category']})")
        click.echo(f"  Path: {rb['path']}")


@cli.command()
@click.argument("file", type=click.Path(exists=True))
def status(file):
    """Check the execution status of a runbook."""
    state = load_state(file)

    click.echo(f"Runbook: {file}")
    click.echo(f"Current step: {state.get('current_step', 1)}")

    if state.get("completed") and state.get("success"):
        click.echo("Status: Completed successfully")
    elif state.get("last_run"):
        click.echo(f"Last run: {state.get('last_run')}")
        if not state.get("success", True):
            click.echo("Status: Interrupted or failed")
            click.echo(f"Resume with: runbook run {file} --resume")
    else:
        click.echo("Status: Not yet run")


if __name__ == "__main__":
    cli()
