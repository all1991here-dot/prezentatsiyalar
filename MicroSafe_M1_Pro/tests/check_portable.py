#!/usr/bin/env python3
"""Compile/test the EA's exact portable block; never emulate MT5 or profitability."""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import re
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


def function_body(content: str, name: str) -> str:
    """Find a simple named production function, retaining braces for inspection."""
    match = re.search(r"\b" + re.escape(name) + r"\s*\([^)]*\)\s*\{", content)
    if not match:
        raise ValueError(f"Required production function missing: {name}")
    opening = content.index("{", match.start())
    depth = 0
    for index in range(opening, len(content)):
        depth += (content[index] == "{") - (content[index] == "}")
        if depth == 0:
            return content[opening:index + 1]
    raise ValueError(f"Unterminated production function: {name}")


def check_regressions(source: Path) -> int:
    """Static change guards, not claims about executing broker-side MQL paths."""
    content = source.read_text(encoding="utf-8")
    # Ignore comments when checking code identifiers, but retain actual strings.
    code = re.sub(r"/\*.*?\*/|//[^\n]*", "", content, flags=re.S)
    checks: list[tuple[bool, str]] = []
    for identifier in (
        "InpLossCooldownMinutes", "InpMaxConsecutiveLosses", "InpStartHour", "InpEndHour",
        "InpFridayStopHour", "InpFridayCloseHour", "lastLoss", "lossStreak", "PERIOD_M15",
    ):
        checks.append((re.search(r"\b" + identifier + r"\b", code) is None, f"removed {identifier}"))
    trading_paths = function_body(code, "Evaluate") + function_body(code, "OnTick")
    checks.append(("day_of_week" not in trading_paths and re.search(r"\.hour\b", trading_paths) is None, "no hour/day-of-week trading gate"))
    daily = function_body(code, "DailyRisk")
    checks.append(("CloseOwn(" not in daily and "OwnOpen(" not in daily, "day rollover does not auto-flatten"))
    checks.append((re.search(r"input\s+double\s+InpDailyLossPercent\s*=\s*2(?:\.0)?\s*;", code) is not None, "default daily loss remains 2 percent"))
    exposure = re.sub(r"\s+", "", function_body(code, "Exposure"))
    checks.append(("returnPositionsTotal()>0||OrdersTotal()>0;" in exposure, "account position/order exposure blocks entry"))
    evaluate = function_body(code, "Evaluate")
    checks.append((evaluate.count("if(Exposure())") >= 2, "exposure checked before evaluation and submission"))
    checks.append(("if(!DailyRisk())" in evaluate, "daily guard remains on entry path"))
    checks.append(("InpDailyLossPercent" in daily and "RiskEquity()" in daily and "Latch(" in daily, "daily equity loss halt retained"))
    checks.append(("MSVolume(budget,minRisk,minLot,maxLot,step)" in evaluate and "volume<minLot" in evaluate, "broker minimum lot risk cannot be forced"))
    checks.append(("OrderCalcProfit(" in evaluate and "OrderCalcMargin(" in evaluate and ">budget+1e-8" in evaluate, "final monetary risk and margin guard retained"))
    checks.append(("InpEnablePullback,InpEnableBreakout" in evaluate, "production passes independent signal toggles"))
    checks.append(("f.breakoutHigh=bars[1].high" in evaluate and "for(int i=2;i<=InpBreakoutLookback;i++)" in evaluate, "breakout levels exclude signal candle"))
    failures = [label for ok, label in checks if not ok]
    for failure in failures:
        print(f"FAIL static regression: {failure}", file=sys.stderr)
    print(f"{len(checks)} static production regressions; {len(failures)} failures", flush=True)
    return len(failures)


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
        if check_regressions(args.source):
            return 1
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
