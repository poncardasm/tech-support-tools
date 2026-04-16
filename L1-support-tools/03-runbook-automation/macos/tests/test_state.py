"""Tests for the runbook state management module."""

import pytest
import json
from pathlib import Path
import tempfile

from runbook.state import (
    get_state_path,
    get_state_dir,
    save_state,
    load_state,
    clear_state,
    list_saved_states,
    setup_resume,
    ExecutionContext,
)


class TestGetStatePath:
    """Test the get_state_path function."""

    def test_returns_correct_path(self):
        path = get_state_path("/path/to/my-runbook.md")
        assert "my-runbook.json" in str(path)
        assert ".config/runbook/state" in str(path)


class TestSaveAndLoadState:
    """Test saving and loading state."""

    def test_save_and_load_roundtrip(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        save_state(str(runbook), step_number=3, success=True)
        state = load_state(str(runbook))

        assert state["current_step"] == 3
        assert state["success"] is True
        assert "last_run" in state

    def test_load_nonexistent_state(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        state = load_state(str(runbook))
        assert state["current_step"] == 1
        assert state["success"] is False

    def test_save_with_metadata(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        save_state(str(runbook), step_number=2, success=True, metadata={"custom": "data"})
        state = load_state(str(runbook))

        assert state["metadata"]["custom"] == "data"


class TestClearState:
    """Test the clear_state function."""

    def test_clear_existing_state(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        save_state(str(runbook), step_number=2)
        assert clear_state(str(runbook)) is True

        # Verify it's gone
        state = load_state(str(runbook))
        assert state["current_step"] == 1

    def test_clear_nonexistent_state(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        # Should not error even if no state exists
        assert clear_state(str(runbook)) is True


class TestListSavedStates:
    """Test the list_saved_states function."""

    def test_list_states(self, tmp_path):
        runbook1 = tmp_path / "test1.md"
        runbook2 = tmp_path / "test2.md"
        runbook1.write_text("# Test 1")
        runbook2.write_text("# Test 2")

        save_state(str(runbook1), step_number=2)
        save_state(str(runbook2), step_number=5)

        states = list_saved_states()

        # Should have at least our two test states
        assert "test1" in states or len(states) >= 2


class TestSetupResume:
    """Test the setup_resume function."""

    def test_resume_from_saved_state(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        save_state(str(runbook), step_number=4)

        start_step = setup_resume(str(runbook), resume=True)
        assert start_step == 4

    def test_resume_no_state(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        start_step = setup_resume(str(runbook), resume=True)
        assert start_step == 1

    def test_no_resume(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        save_state(str(runbook), step_number=7)

        # Without resume flag, should start from 1
        start_step = setup_resume(str(runbook), resume=False)
        assert start_step == 1

    def test_resume_completed_runbook(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        save_state(str(runbook), step_number=5, success=True)

        # When completed, should still return saved step
        # (UI layer decides to show message and start from 1)
        start_step = setup_resume(str(runbook), resume=True)
        assert start_step == 5


class TestExecutionContext:
    """Test the ExecutionContext class."""

    def test_context_manager(self, tmp_path):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        with ExecutionContext(str(runbook), 1) as ctx:
            assert ctx.current_step == 1
            ctx.update_step(3)
            assert ctx.current_step == 3

    def test_state_saved_on_interrupt(self, tmp_path, monkeypatch):
        runbook = tmp_path / "test.md"
        runbook.write_text("# Test")

        def raise_keyboard_interrupt(*args):
            raise KeyboardInterrupt()

        try:
            with ExecutionContext(str(runbook), 1) as ctx:
                ctx.update_step(2)
                raise KeyboardInterrupt()
        except KeyboardInterrupt:
            pass

        # Verify state was saved
        state = load_state(str(runbook))
        assert state["current_step"] == 2
