"""State management for runbook execution."""

import json
import signal
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional


def get_state_dir() -> Path:
    """Get the state directory path.

    Returns:
        Path to the state directory (~/.config/runbook/state).
    """
    state_dir = Path.home() / ".config" / "runbook" / "state"
    state_dir.mkdir(parents=True, exist_ok=True)
    return state_dir


def get_state_path(file_path: str) -> Path:
    """Get the state file path for a runbook.

    Args:
        file_path: Path to the runbook file.

    Returns:
        Path to the state JSON file.
    """
    state_dir = get_state_dir()
    # Use the runbook filename (without extension) as the state filename
    runbook_name = Path(file_path).stem
    return state_dir / f"{runbook_name}.json"


def save_state(
    file_path: str, step_number: int, success: bool = True, metadata: Optional[Dict] = None
) -> None:
    """Save the current execution state.

    Args:
        file_path: Path to the runbook file.
        step_number: Current step number.
        success: Whether the step completed successfully.
        metadata: Optional additional metadata to store.
    """
    state_file = get_state_path(file_path)

    state = {
        "runbook": str(Path(file_path).resolve()),
        "current_step": step_number,
        "last_run": datetime.now().isoformat(),
        "success": success,
        "completed": success,  # Mark as completed if successful
    }

    if metadata:
        state["metadata"] = metadata

    # Write atomically to avoid corruption
    temp_file = state_file.with_suffix(".tmp")
    temp_file.write_text(json.dumps(state, indent=2))
    temp_file.rename(state_file)


def load_state(file_path: str) -> Dict:
    """Load the saved execution state.

    Args:
        file_path: Path to the runbook file.

    Returns:
        State dictionary with at least 'current_step' key.
        Returns default state if no state exists.
    """
    state_file = get_state_path(file_path)

    if state_file.exists():
        try:
            state = json.loads(state_file.read_text())
            # Ensure required keys exist
            state.setdefault("current_step", 1)
            state.setdefault("success", False)
            return state
        except (json.JSONDecodeError, IOError):
            # Corrupted or unreadable state file
            pass

    # Default state
    return {"runbook": str(Path(file_path).resolve()), "current_step": 1, "success": False}


def clear_state(file_path: str) -> bool:
    """Clear the saved state for a runbook.

    Args:
        file_path: Path to the runbook file.

    Returns:
        True if state was cleared (or didn't exist), False on error.
    """
    state_file = get_state_path(file_path)

    if state_file.exists():
        try:
            state_file.unlink()
            return True
        except IOError:
            return False

    return True


def list_saved_states() -> Dict[str, Dict]:
    """List all saved runbook states.

    Returns:
        Dictionary mapping runbook names to their states.
    """
    state_dir = get_state_dir()
    states = {}

    if not state_dir.exists():
        return states

    for state_file in state_dir.glob("*.json"):
        try:
            state = json.loads(state_file.read_text())
            states[state_file.stem] = state
        except (json.JSONDecodeError, IOError):
            continue

    return states


class ExecutionContext:
    """Context manager for handling execution state and signals."""

    def __init__(self, file_path: str, start_step: int = 1):
        self.file_path = file_path
        self.start_step = start_step
        self.current_step = start_step
        self.interrupted = False
        self._original_handler = None

    def __enter__(self):
        """Set up signal handlers and load initial state."""
        # Save original SIGINT handler
        self._original_handler = signal.signal(signal.SIGINT, self._handle_interrupt)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Restore signal handlers and save final state."""
        # Restore original handler
        if self._original_handler is not None:
            signal.signal(signal.SIGINT, self._original_handler)

        # Save state if we were interrupted
        if self.interrupted:
            save_state(self.file_path, self.current_step, success=False)
            print(f"\n[INTERRUPTED] State saved at step {self.current_step}")
            print(f"Resume with: runbook run {self.file_path} --resume")

        return False  # Don't suppress exceptions

    def _handle_interrupt(self, signum, frame):
        """Handle Ctrl+C interrupt."""
        self.interrupted = True
        print("\n[!] Interrupted by user (Ctrl+C)")
        # Re-raise to allow normal cleanup
        raise KeyboardInterrupt()

    def update_step(self, step_number: int):
        """Update the current step number."""
        self.current_step = step_number


def setup_resume(file_path: str, resume: bool = False) -> int:
    """Determine the starting step based on resume flag.

    Args:
        file_path: Path to the runbook file.
        resume: Whether to resume from saved state.

    Returns:
        Step number to start from (1-indexed).
    """
    if resume:
        state = load_state(file_path)
        current_step = state.get("current_step", 1)

        # If runbook was previously completed successfully, start from beginning
        if state.get("completed", False) and state.get("success", False):
            print(f"[INFO] Runbook was previously completed. Starting from step 1.")
            return 1

        print(f"[INFO] Resuming from step {current_step}")
        return current_step

    return 1
