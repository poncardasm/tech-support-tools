"""Step and runbook execution engine."""

import subprocess
import sys
from typing import Dict, List, Optional, Callable

from .parser import Step, parse_runbook
from .state import save_state


class StepExecutionError(Exception):
    """Raised when a step fails to execute."""

    def __init__(self, step: Step, exit_code: int, output: str, error: str):
        self.step = step
        self.exit_code = exit_code
        self.output = output
        self.error = error
        super().__init__(f"Step {step.number} failed with exit code {exit_code}")


def execute_step(
    step: Step, total: int, dry_run: bool = False, on_output: Optional[Callable[[str], None]] = None
) -> Dict[str, any]:
    """Execute a single runbook step.

    Args:
        step: The Step object to execute.
        total: Total number of steps (for display).
        dry_run: If True, print command without executing.
        on_output: Optional callback for real-time output streaming.

    Returns:
        Dictionary with 'exit_code', 'output', 'error', and 'success' keys.
    """
    # Display step info
    code_preview = step.code.replace("\n", " ")[:50]
    if len(step.code) > 50:
        code_preview += "..."

    print(f"\n[STEP {step.number}/{total}] {code_preview}")
    print("-" * 60)

    if dry_run:
        print("DRY RUN - Command would execute:")
        print(f"  $ {step.code[:80]}")
        if len(step.code) > 80:
            print(f"  ... ({len(step.code)} chars total)")
        return {"exit_code": 0, "output": "", "error": "", "success": True}

    # Execute the command
    try:
        result = subprocess.run(
            step.code, shell=True, capture_output=True, text=True, executable="/bin/bash"
        )

        # Print output if any
        if result.stdout:
            print(result.stdout.rstrip())
            if on_output:
                on_output(result.stdout)

        # Print error if any (but don't treat as fatal yet)
        if result.stderr:
            print(f"  (stderr): {result.stderr.rstrip()[:200]}", file=sys.stderr)

        success = result.returncode == 0

        return {
            "exit_code": result.returncode,
            "output": result.stdout,
            "error": result.stderr,
            "success": success,
        }

    except Exception as e:
        error_msg = str(e)
        print(f"  ERROR: {error_msg}", file=sys.stderr)
        return {"exit_code": -1, "output": "", "error": error_msg, "success": False}


def prompt_on_failure(step: Step, result: Dict[str, any]) -> str:
    """Prompt user for action when a step fails.

    Args:
        step: The Step that failed.
        result: Execution result dictionary.

    Returns:
        User choice: 's' (skip), 'f' (force continue), or 'a' (abort).
    """
    print(f"\n[!] Step {step.number} failed with exit code {result['exit_code']}")

    if result["error"]:
        print(f"Error: {result['error'][:200]}")

    print("\n[DID NOT EXPECT THIS] Stopping. Options:")
    print("  [s] Skip this step and continue")
    print("  [f] Force continue (ignore failures)")
    print("  [a] Abort execution")

    while True:
        try:
            choice = input("> ").strip().lower()
            if choice in ("s", "skip"):
                return "s"
            elif choice in ("f", "force", "continue"):
                return "f"
            elif choice in ("a", "abort", "q", "quit"):
                return "a"
            else:
                print("Please enter 's' (skip), 'f' (force), or 'a' (abort)")
        except (EOFError, KeyboardInterrupt):
            print("\nAborting...")
            return "a"


def execute_runbook(
    file_path: str,
    from_step: int = 1,
    dry_run: bool = False,
    on_step_start: Optional[Callable[[Step], None]] = None,
    on_step_complete: Optional[Callable[[Step, Dict], None]] = None,
) -> bool:
    """Execute a complete runbook.

    Args:
        file_path: Path to the markdown runbook.
        from_step: Step number to start from (1-indexed).
        dry_run: If True, show commands without executing.
        on_step_start: Optional callback before each step.
        on_step_complete: Optional callback after each step.

    Returns:
        True if runbook completed successfully, False otherwise.
    """
    # Parse the runbook
    try:
        steps = parse_runbook(file_path)
    except Exception as e:
        print(f"Error parsing runbook: {e}", file=sys.stderr)
        return False

    if not steps:
        print("No executable steps found in runbook.")
        return True

    total = len(steps)

    # Validate from_step
    if from_step < 1:
        from_step = 1
    if from_step > total:
        print(f"Starting step {from_step} is beyond the last step ({total})")
        return False

    if from_step > 1:
        print(f"Starting from step {from_step} of {total}")
    else:
        print(f"Executing {total} step(s)...")

    # Execute steps in sequence
    force_continue = False

    for step in steps[from_step - 1 :]:
        if on_step_start:
            on_step_start(step)

        result = execute_step(step, total, dry_run)

        if on_step_complete:
            on_step_complete(step, result)

        # Save state after each step (for resume functionality)
        if not dry_run:
            save_state(file_path, step.number, result["success"])

        # Handle failures
        if not result["success"] and not dry_run and not force_continue:
            choice = prompt_on_failure(step, result)

            if choice == "a":
                print("\n[ABORTED] Runbook execution stopped.")
                return False
            elif choice == "f":
                force_continue = True
                print("Continuing (ignoring future failures)...")
            elif choice == "s":
                print("Skipping and continuing...")

        # Small delay between steps for readability
        if not dry_run and step.number < total:
            import time

            time.sleep(0.1)

    if dry_run:
        print(f"\n[DRY RUN] Would have executed {total} step(s)")
    else:
        print("\n[OK] Runbook completed successfully")

    return True


def show_runbook_steps(file_path: str) -> bool:
    """Display all steps in a runbook without executing.

    Args:
        file_path: Path to the markdown runbook.

    Returns:
        True if steps were displayed, False on error.
    """
    try:
        steps = parse_runbook(file_path)
    except Exception as e:
        print(f"Error parsing runbook: {e}", file=sys.stderr)
        return False

    if not steps:
        print("No executable steps found in runbook.")
        return True

    print(f"\nRunbook: {file_path}")
    print(f"Total steps: {len(steps)}")
    print("=" * 60)

    for step in steps:
        code_lines = step.code.strip().split("\n")
        first_line = code_lines[0][:60]
        if len(code_lines) > 1:
            first_line += f" ... ({len(code_lines)} lines)"

        print(f"\n[{step.number}] {first_line}")
        print(f"    Language: {step.language}")

    print("\n" + "=" * 60)
    return True
