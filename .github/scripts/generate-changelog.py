#!/usr/bin/env python3
"""
Generate changelog from git history for BamOS releases.

Usage:
    python3 .github/scripts/generate-changelog.py <last_tag> <current_tag> <repo>

Output:
    Markdown changelog to stdout

Example:
    python3 .github/scripts/generate-changelog.py v4.0.0.20260709.1 v4.0.0.20260710.1 quocnho/bamos
"""

import subprocess
import sys
import re


def get_commits_since_tag(last_tag: str) -> list[dict]:
    """Get all commits since the given tag."""
    result = subprocess.run(
        ["git", "log", "--pretty=format:%H|%an|%s", f"{last_tag}..HEAD"],
        capture_output=True, text=True
    )

    commits = []
    for line in result.stdout.strip().split("\n"):
        if not line:
            continue
        parts = line.split("|", 2)
        if len(parts) < 3:
            continue
        commits.append({
            "hash": parts[0],
            "author": parts[1],
            "subject": parts[2],
        })
    return commits


def get_all_commits() -> list[dict]:
    """Get all commits (for first release)."""
    result = subprocess.run(
        ["git", "log", "--pretty=format:%H|%an|%s"],
        capture_output=True, text=True
    )

    commits = []
    for line in result.stdout.strip().split("\n"):
        if not line:
            continue
        parts = line.split("|", 2)
        if len(parts) < 3:
            continue
        commits.append({
            "hash": parts[0],
            "author": parts[1],
            "subject": parts[2],
        })
    return commits


def categorize_commit(subject: str) -> str:
    """Categorize a commit by its conventional commit prefix."""
    subject_lower = subject.lower()

    # Feature
    if subject_lower.startswith("feat") or subject_lower.startswith("feature"):
        return "✨ Features"

    # Bug fix
    if subject_lower.startswith("fix"):
        return "🐛 Bug Fixes"

    # Documentation
    if subject_lower.startswith("docs"):
        return "📚 Documentation"

    # Style/UI
    if subject_lower.startswith("style"):
        return "🎨 Style"

    # Refactor
    if subject_lower.startswith("refactor") or subject_lower.startswith("rework"):
        return "♻️ Refactor"

    # Performance
    if subject_lower.startswith("perf"):
        return "⚡ Performance"

    # Tests
    if subject_lower.startswith("test"):
        return "✅ Tests"

    # Chores / maintenance
    if subject_lower.startswith("chore") or subject_lower.startswith("ci") or subject_lower.startswith("build"):
        return "🔧 Chores"

    # Default
    return "🔄 Other"


def clean_subject(subject: str) -> str:
    """Remove conventional commit prefix from subject."""
    patterns = [
        r"^feat(\([^)]*\))?:\s*",
        r"^feature(\([^)]*\))?:\s*",
        r"^fix(\([^)]*\))?:\s*",
        r"^docs(\([^)]*\))?:\s*",
        r"^style(\([^)]*\))?:\s*",
        r"^refactor(\([^)]*\))?:\s*",
        r"^perf(\([^)]*\))?:\s*",
        r"^test(\([^)]*\))?:\s*",
        r"^chore(\([^)]*\))?:\s*",
        r"^ci(\([^)]*\))?:\s*",
        r"^build(\([^)]*\))?:\s*",
    ]
    for pattern in patterns:
        cleaned = re.sub(pattern, "", subject, count=1)
        if cleaned != subject:
            return cleaned.strip()
    return subject.strip()


def generate_changelog(last_tag: str | None, current_tag: str, repo: str) -> str:
    """Generate full changelog markdown."""
    if last_tag:
        commits = get_commits_since_tag(last_tag)
        title = f"## What Changed (since {last_tag})"
    else:
        commits = get_all_commits()
        title = "## 🎉 Initial Release"

    # Group by category
    categories = {
        "✨ Features": [],
        "🐛 Bug Fixes": [],
        "📚 Documentation": [],
        "🎨 Style": [],
        "♻️ Refactor": [],
        "⚡ Performance": [],
        "✅ Tests": [],
        "🔧 Chores": [],
        "🔄 Other": [],
    }

    for c in commits:
        cat = categorize_commit(c["subject"])
        short_hash = c["hash"][:7]
        url = f"https://github.com/{repo}/commit/{c['hash']}"
        clean_subj = clean_subject(c["subject"])
        categories[cat].append((short_hash, url, clean_subj, c["author"]))

    lines = []
    lines.append(title)
    lines.append("")

    for category, items in categories.items():
        if items:
            lines.append(f"### {category}")
            for short_hash, url, subject, author in items:
                lines.append(f"- [{short_hash}]({url}) — {subject} ({author})")
            lines.append("")

    if last_tag:
        lines.append("---")
        compare_url = f"https://github.com/{repo}/compare/{last_tag}...{current_tag}"
        lines.append(f"**Full Changelog:** [{last_tag}...{current_tag}]({compare_url})")
    else:
        lines.append(f"**Full Changelog:** [commits](https://github.com/{repo}/commits/{current_tag})")

    return "\n".join(lines)


def main():
    if len(sys.argv) < 3:
        print("Usage: generate-changelog.py <last_tag|none> <current_tag> <repo>", file=sys.stderr)
        sys.exit(1)

    last_tag = None if sys.argv[1] == "none" else sys.argv[1]
    current_tag = sys.argv[2]
    repo = sys.argv[3]

    changelog = generate_changelog(last_tag, current_tag, repo)
    print(changelog)


if __name__ == "__main__":
    main()
