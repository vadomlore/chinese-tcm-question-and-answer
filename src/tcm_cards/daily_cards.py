from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re


@dataclass
class QuestionCard:
    index: int
    question: str
    answer: str
    keywords: str
    hint: str


@dataclass
class ReviewSession:
    source_file: str | None
    review_date: str
    cards: list[QuestionCard]
    empty_reason: str | None = None


SECTION_HEADER = "## Daily Questions (AI Generated)"


def _extract_field(block: str, labels: list[str]) -> str:
    for label in labels:
        pattern = rf"^-\s*{re.escape(label)}\s*[:：]\s*(.+)$"
        match = re.search(pattern, block, re.MULTILINE)
        if match:
            return match.group(1).strip()
    return ""


def parse_daily_cards(markdown_text: str) -> list[QuestionCard]:
    if SECTION_HEADER not in markdown_text:
        return []

    section = markdown_text.split(SECTION_HEADER, 1)[1]
    section = section.split("## Notes", 1)[0]
    chunks = re.split(r"^###\s+\d+\s*$", section, flags=re.MULTILINE)

    cards: list[QuestionCard] = []
    for chunk in chunks:
        block = chunk.strip()
        if not block or "Waiting for generation" in block:
            continue

        question = _extract_field(block, ["问题", "Question"])
        answer = _extract_field(block, ["答案", "Answer"])
        keywords = _extract_field(block, ["关键词", "Keywords"])
        hint = _extract_field(block, ["复习提示", "Review Hint"])

        if not question:
            continue

        cards.append(
            QuestionCard(
                index=len(cards) + 1,
                question=question,
                answer=answer or "未填写答案",
                keywords=keywords or "待补充",
                hint=hint or "适合短时复习",
            )
        )

    return cards


def _list_daily_files(data_dir: Path) -> list[Path]:
    if not data_dir.exists():
        return []
    return sorted(path for path in data_dir.glob("*.md") if path.is_file())


def load_review_session(data_dir: Path, review_date: str) -> ReviewSession:
    files = _list_daily_files(data_dir)
    if not files:
        return ReviewSession(
            source_file=None,
            review_date=review_date,
            cards=[],
            empty_reason="还没有每日题库文件。先用 Copilot 生成当天题目，再回来练习。",
        )

    target_name = f"{review_date}.md"
    previous_candidates = [path for path in files if path.name < target_name]
    candidates = list(reversed(previous_candidates or files))

    for candidate in candidates:
        cards = parse_daily_cards(candidate.read_text(encoding="utf-8"))
        if cards:
            return ReviewSession(
                source_file=candidate.name,
                review_date=review_date,
                cards=cards,
            )

    return ReviewSession(
        source_file=candidates[0].name if candidates else None,
        review_date=review_date,
        cards=[],
        empty_reason="已经找到每日题库文件，但其中还没有可练习的问答内容。先执行一次 /生成中医问答题。",
    )
