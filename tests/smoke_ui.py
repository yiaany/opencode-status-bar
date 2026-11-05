"""Isolated macOS UI smoke test. Requires Accessibility permission for osascript."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

binary = Path("build/OpenCode Status Bar.app/Contents/MacOS/OpenCodeStatusBar").resolve()
base = os.environ.get("TMPDIR")
with tempfile.TemporaryDirectory(prefix="opencode-status-smoke-", dir=base) as directory:
    process = subprocess.Popen([str(binary)], env={**os.environ, "OPENCODE_STATUS_BAR_STATE_DIR": directory})
    try:
        for state, label, expected in [
            ("working", "Thinking…", "Thinking…"),
            ("permission", "Awaiting approval", "Awaiting approval"),
            ("unread", "Completed", "Completed"),
        ]:
            now = time.time()
            record = dict(id="ses_smoke", state=state, label=label, directory="/smoke-test", title="Smoke test", startedAt=now - 75, updatedAt=now, source="opencode")
            temporary = Path(directory) / "state.tmp"
            temporary.write_text(json.dumps(record))
            temporary.replace(Path(directory) / "state.json")
            for attempt in range(20):
                time.sleep(0.2)
                result = subprocess.run(["osascript", "-e", 'tell application "System Events" to get title of menu bar items of menu bar 1 of process "OpenCodeStatusBar"'], capture_output=True, text=True)
                if expected in result.stdout:
                    break
            else:
                raise AssertionError(f"{state}: expected {expected!r}; got {result.stdout!r} {result.stderr!r}")
            print(f"PASS: {state} → {result.stdout.strip()}")
        (Path(directory) / "state.json").unlink()
        time.sleep(0.4)
        assert process.poll() is None, "app exited unexpectedly"
        print("PASS: empty state, app remains running")
    finally:
        process.terminate()
        process.wait(timeout=5)
