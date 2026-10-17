"""UniGuide oqim metrikalari: faqat Python standart kutubxonasi."""

from __future__ import annotations

import argparse
import csv
import json
from datetime import date
from pathlib import Path
from statistics import mean

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FIELDS = {"id", "article_id", "title", "queued", "started", "done"}


def parse_date(value: str, field: str, row_id: str, required: bool = False) -> date | None:
    if not value:
        if required:
            raise ValueError(f"{row_id}: {field} sanasi kerak.")
        return None
    try:
        result = date.fromisoformat(value)
    except (ValueError, TypeError) as error:
        raise ValueError(f"{row_id}: {field} uchun YYYY-MM-DD kerak: {value!r}.") from error
    # Reject compact ISO dates accepted by newer Python releases.
    if result.isoformat() != value:
        raise ValueError(f"{row_id}: {field} uchun YYYY-MM-DD kerak.")
    return result


def read_items(path: Path | str) -> list[dict]:
    with Path(path).open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if not REQUIRED_FIELDS.issubset(reader.fieldnames or []):
            raise ValueError("CSV ustunlari: id, article_id, title, queued, started, done kerak.")
        items, identifiers = [], set()
        for line, row in enumerate(reader, 2):
            if None in row or any(value is None for value in row.values()):
                raise ValueError(f"{line}-qator: CSV kataklari soni noto‘g‘ri.")
            row_id = row["id"].strip()
            if not row_id or row_id in identifiers:
                raise ValueError(f"{line}-qator: id bo‘sh yoki takrorlangan.")
            if not row["article_id"].strip() or not row["title"].strip():
                raise ValueError(f"{row_id}: article_id va title bo‘sh bo‘lmasin.")
            identifiers.add(row_id)
            queued = parse_date(row["queued"], "queued", row_id, required=True)
            started = parse_date(row["started"], "started", row_id)
            done = parse_date(row["done"], "done", row_id)
            if done is not None and started is None:
                raise ValueError(f"{row_id}: done mavjud, started yo‘q.")
            if started is not None and started < queued:
                raise ValueError(f"{row_id}: started queued dan oldin bo‘lolmaydi.")
            if done is not None and done < started:
                raise ValueError(f"{row_id}: done started dan oldin bo‘lolmaydi.")
            items.append({"id": row_id, "article_id": row["article_id"], "title": row["title"],
                          "queued": queued, "started": started, "done": done})
    if not items:
        raise ValueError("CSVda kamida bitta ish bo‘lishi kerak.")
    return items


def calculate(items: list[dict], start: date, end: date, asof: date) -> dict:
    if end <= start:
        raise ValueError("end start dan keyin bo‘lishi kerak.")
    days = (end - start).days
    # A fixed half-open window prevents boundary double-counting.
    completed = [item for item in items if item["done"] is not None and start <= item["done"] < end]
    active = [item for item in items if item["started"] is not None and item["started"] <= asof
              and (item["done"] is None or item["done"] > asof)]
    durations = [{"id": item["id"], "lead_days": (item["done"] - item["queued"]).days,
                  "cycle_days": (item["done"] - item["started"]).days} for item in completed]
    ages = [{"id": item["id"], "age_days": (asof - item["started"]).days} for item in active]
    return {
        "data_kind": "synthetic teaching sample — not actual student performance",
        "window_start_inclusive": start.isoformat(), "window_end_exclusive": end.isoformat(),
        "observation_days": days, "asof": asof.isoformat(), "completed_count": len(completed),
        "mean_lead_days": mean(row["lead_days"] for row in durations) if durations else None,
        "mean_cycle_days": mean(row["cycle_days"] for row in durations) if durations else None,
        "throughput_per_day": len(completed) / days, "wip": len(active),
        "mean_age_days": mean(row["age_days"] for row in ages) if ages else None,
        "completed_items": durations, "active_item_ages": ages,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="O‘quv CSV uchun lead/cycle/throughput/WIP/age.")
    parser.add_argument("--csv", type=Path, default=ROOT / "data" / "flow_data.csv")
    parser.add_argument("--start", default="2026-09-01", help="Kiritilgan birinchi kun")
    parser.add_argument("--end", default="2026-09-11", help="Kiritilmagan chegara kuni")
    parser.add_argument("--asof", default="2026-09-10", help="WIP va age kesimi")
    parser.add_argument("--json", action="store_true", help="Mashinada qayta ishlash uchun JSON")
    args = parser.parse_args()
    try:
        result = calculate(read_items(args.csv), parse_date(args.start, "start", "CLI", True),
                           parse_date(args.end, "end", "CLI", True),
                           parse_date(args.asof, "asof", "CLI", True))
    except (OSError, ValueError) as error:
        parser.exit(2, f"XATO: {error}\n")
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print("SUN’IY O‘QUV MISOLI — haqiqiy jamoa hisobotiga almashtirmang")
        print(f"Kuzatuv: [{args.start}, {args.end}); {result['observation_days']} kalendar kun")
        print(f"Tugallangan: {result['completed_count']}")
        for label, key in (("O‘rtacha lead time", "mean_lead_days"),
                           ("O‘rtacha cycle time", "mean_cycle_days")):
            value = result[key]
            print(f"{label}: {value:.4f} kun" if value is not None else f"{label}: N/A")
        print(f"Throughput: {result['throughput_per_day']:.4f} ish/kun")
        print(f"WIP ({args.asof}): {result['wip']}")
        print("Tugallangan ishlar (lead; cycle):")
        for item in result["completed_items"]:
            print(f"  {item['id']}: {item['lead_days']}; {item['cycle_days']} kun")
        print("Boshlangan, shu kesimda tugamagan ishlar yoshi:")
        for item in result["active_item_ages"]:
            print(f"  {item['id']}: {item['age_days']} kun")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
