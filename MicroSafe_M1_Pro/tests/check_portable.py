#!/usr/bin/env python3
"""Compile/test the EA's exact portable block; never emulate MT5 or profitability."""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


BEGIN = "// BEGIN PORTABLE LOGIC"
END = "// END PORTABLE LOGIC"


def extract(source: Path) -> str:
    content = source.read_text(encoding="utf-8")
    if content.count(BEGIN) != 1 or content.count(END) != 1:
        raise ValueError("Expected exactly one pair of portable-logic markers")
    prefix, block = content.split(BEGIN, 1)
    block, suffix = block.split(END, 1)
    if "int MSDirection(" not in block or "double MSVolume(" not in block:
        raise ValueError("The marked block does not contain both tested functions")
    return block


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parents[1] / "EURUSD_MicroSafe_M1_Pro.mq5")
    parser.add_argument("--compiler", default=os.environ.get("CXX", "g++"))
    args = parser.parse_args()
    compiler = shutil.which(args.compiler)
    if compiler is None:
        print(f"C++ compiler unavailable: {args.compiler}", file=sys.stderr)
        return 2
    try:
        block = extract(args.source)
        digest = hashlib.sha256(block.encode("utf-8")).hexdigest()
        harness = Path(__file__).with_name("portable_harness.cpp")
        with tempfile.TemporaryDirectory(prefix="microsafe-portable-") as tmp:
            root = Path(tmp)
            header = (
                "#pragma once\n#include <algorithm>\n#include <cmath>\n"
                "inline double MathAbs(double x) { return std::fabs(x); }\n"
                "inline double MathMin(double a,double b) { return std::min(a,b); }\n"
                "inline double MathFloor(double x) { return std::floor(x); }\n"
                "inline bool MathIsValidNumber(double x) { return std::isfinite(x); }\n"
            )
            (root / "portable_logic.hpp").write_text(header + block, encoding="utf-8")
            binary = root / "portable_checks"
            subprocess.run(
                [compiler, "-std=c++17", "-O2", "-Wall", "-Wextra", "-Werror", "-pedantic", "-I", str(root), str(harness), "-o", str(binary)],
                check=True,
            )
            print(f"Exact MQL portable-block SHA256: {digest}", flush=True)
            outcome = subprocess.run([str(binary)], check=False)
            if extract(args.source) != block:
                print("Portable source changed during testing; rerun checks", file=sys.stderr)
                return 2
            print("Scope: extracted signal/volume arithmetic only; no MQL5 compilation, MT5 execution, backtest, or win-rate evidence.", flush=True)
            return outcome.returncode
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"Portable check could not finish: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
