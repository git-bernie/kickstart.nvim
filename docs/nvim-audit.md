# nvim-audit

Periodic health review of this Neovim config. Run `/nvim-audit` in Claude Code.

## What it checks

Five dimensions: startup and in-editor performance, correctness (health, tool liveness), keymap and UX efficiency, tool coverage against the stated work profile, and currency with the wider Neovim ecosystem.

## Parts

| Path | Role |
|------|------|
| `bin/nvim-audit-evidence.sh` | Measurement pass. Deterministic, read-only, runnable on its own. Optional output-dir arg; defaults to `~/.cache/nvim-audit/<date>`. Prints the directory it used. |
| `.claude/commands/nvim-audit.md` | The command — runs the script, does the ecosystem research, writes the report. |
| `docs/nvim-audit-YYYY-MM-DD.md` | The report from each run. |

Measurement is split from reasoning so a bad number can be debugged without re-running the whole audit.

## Contract

The audit never edits config. Findings that warrant an edit ship as an exact diff in the report, unapplied.

## Report tiers

Findings are tiered by how much they should be trusted, not by topic:

- **Verified** — backed by a measurement or cited source, shown inline.
- **Judgment call** — reasoned from the config, not measured.
- **Experimental** — keymap ergonomics, inferred rather than measured. Each run checks whether the last run's experimental suggestions were adopted, so the tier earns or loses credibility instead of repeating itself.

Full report format and audit rules live in [`.claude/commands/nvim-audit.md`](../.claude/commands/nvim-audit.md) — this doc orients, that file governs.

## Cadence

Quarterly is about right. The ecosystem phase is the slow part and is skipped when the nvim version has not moved since the last report.

## Running the measurement alone

    ./bin/nvim-audit-evidence.sh /tmp/audit-check
    jq -r '.[] | select(.executable==false) | .name' /tmp/audit-check/tools.json

That second command answers "is anything I have configured actually missing from PATH" without involving Claude at all.
