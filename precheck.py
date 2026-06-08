#!/usr/bin/env python3
"""
precheck.py - Arenza Swift Static Pre-Check
Run before `git push` to catch the exact errors that have been hitting CI.
Usage: python precheck.py

Checks performed:
  1. Duplicate Data.hexString extension (must only be in SecureEnclaveManager.swift)
  2. Invalid .NSBundleDidLoad notification name
  3. Wrong UserPrediction init arg label (streakMultiplier vs streakMultiplierApplied)
  4. @MainActor-isolated singleton accessed from a nonisolated synchronous context
  5. Mutable `var` captured in a Timer/Task closure (Swift 6 concurrency violation)
  6. Type-checker-intensive .map() closures that may cause compile timeout
"""

import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent
SWIFT_DIR = ROOT / "packages" / "arenza-ios" / "Arenza"

MAIN_ACTOR_SINGLETONS = [
    "ProfileEngine.shared",
    "ContextualMomentService.shared",
    "AnomalyDetector.shared",
    "HouseAdCache.shared",
    "PredictionEngine.shared",
    "BettingMomentTrigger",
]

errors   = []
warnings = []


def add_error(path, line_num, rule, msg):
    rel = str(path.relative_to(ROOT))
    errors.append(f"[{rule}] {rel}:{line_num}  {msg}")


def add_warning(path, line_num, rule, msg):
    rel = str(path.relative_to(ROOT))
    warnings.append(f"[{rule}] {rel}:{line_num}  {msg}")


def check_file(path: Path):
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()

    # Track current context for actor-isolation checks
    in_main_actor_class = False
    in_actor = False
    in_async_func = False

    for i, line in enumerate(lines, start=1):
        stripped = line.strip()

        # --- Context tracking ---
        if re.search(r"@MainActor\s*(final\s*)?class|@MainActor\s*(final\s*)?struct", line):
            in_main_actor_class = True
        if re.match(r"\s*(final\s*)?actor\s+\w+", line):
            in_actor = True
        if re.search(r"func\s+\w+.*async", line):
            in_async_func = True

        # CHECK 1: Duplicate Data.hexString extension
        if "extension Data" in line and "SecureEnclaveManager" not in str(path):
            lookahead = " ".join(lines[i:i+4])
            if "hexString" in lookahead:
                add_error(path, i, "DUP-EXT",
                    "Duplicate Data.hexString extension. Canonical is in SecureEnclaveManager.swift. Remove this one.")

        # CHECK 2: Invalid notification name
        if ".NSBundleDidLoad" in line:
            add_error(path, i, "BAD-NOTIF",
                ".NSBundleDidLoad is not a valid NSNotification.Name — use NWPathMonitor instead.")

        # CHECK 3: Wrong UserPrediction argument label
        if "streakMultiplier:" in line and "streakMultiplierApplied" not in line:
            context = " ".join(lines[max(0, i-6):i])
            if "UserPrediction" in context:
                add_error(path, i, "WRONG-ARG",
                    "UserPrediction uses 'streakMultiplierApplied:' not 'streakMultiplier:'")

        # CHECK 4: @MainActor singleton accessed from nonisolated synchronous context
        if not stripped.startswith("//") and not in_main_actor_class and not in_actor and not in_async_func:
            for singleton in MAIN_ACTOR_SINGLETONS:
                if singleton + "." in line:
                    # Check it's not inside an async closure or await MainActor.run
                    context = " ".join(lines[max(0, i-8):i])
                    if "await MainActor.run" not in context and "Task {" not in context:
                        add_warning(path, i, "ISOLATION",
                            f"'{singleton}' is @MainActor — accessing from nonisolated sync context may cause Swift 6 error: {stripped[:80]}")
                        break

        # CHECK 5: Mutable captured var in Timer/Task closure
        if re.match(r"\s*var\s+\w+\s*=\s*\d+", line):
            lookahead = " ".join(lines[i:i+12])
            if re.search(r"Timer\.scheduledTimer|Task\s*\{", lookahead):
                varname = re.search(r"var\s+(\w+)", line)
                if varname:
                    # Check if the var is used inside the closure
                    if varname.group(1) in lookahead:
                        add_error(path, i, "CONCUR",
                            f"'var {varname.group(1)}' captured and mutated in concurrent closure — move to class property.")

        # CHECK 6: Complex .map closure (type-checker timeout risk)
        if re.search(r"\.map\s*\{", line):
            lookahead = " ".join(lines[i:i+20])
            uuid_count = lookahead.count("UUID()")
            random_count = lookahead.count(".random(")
            if uuid_count >= 2 and random_count >= 2:
                add_warning(path, i, "TYPECHK",
                    "Complex .map closure with multiple UUID() and .random() may cause type-checker timeout — use a for-loop with typed vars.")


def main():
    if not SWIFT_DIR.exists():
        print(f"ERROR: Swift source dir not found: {SWIFT_DIR}")
        sys.exit(1)

    swift_files = list(SWIFT_DIR.rglob("*.swift"))
    print(f"\nArenza Swift Pre-Check — {len(swift_files)} files scanned\n")

    for f in sorted(swift_files):
        check_file(f)

    if not errors and not warnings:
        print("  PASS — no issues found.")
        sys.exit(0)

    if errors:
        print(f"  ERRORS ({len(errors)}):")
        for e in errors:
            print(f"    {e}")
        print()

    if warnings:
        print(f"  WARNINGS ({len(warnings)}):")
        for w in warnings:
            print(f"    {w}")
        print()

    if errors:
        print(f"  FAIL — fix {len(errors)} error(s) before pushing.")
        sys.exit(1)
    else:
        print(f"  OK — {len(warnings)} warning(s) only.")
        sys.exit(0)


if __name__ == "__main__":
    main()
